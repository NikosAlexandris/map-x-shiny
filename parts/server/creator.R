observe({ 
  if(
    mxReact$allowViewsCreator &&
    isTRUE(mxReact$mapPanelMode == "mapViewsCreator")
    ){

    #
    # Update map coordinate values
    #

    observe({
      if(isTRUE(mxReact$mapPanelMode == "mapViewsCreator")){
        bounds <- input$mapxMap_bounds
        output$txtLiveCoordinate <- renderText({
          paste(names(bounds),round(as.numeric(bounds),digits=3),collapse="; ")
        })
      } 
    })



    observe({
      class = input$selNewLayerClass
      if(!noDataCheck(class)){
        updateSelectInput(session,"selNewLayerSubClass",choices=mxConfig$subclass[[class]])
      }
    })



    # new layer name validation

    observe({

      err = character(0)
      info = character(0)
      out  = character(0)
      msgList = character(0)


      cty <- mxReact$selectCountry
      ymn <- input$selNewLayerStartYear
      ymx <- input$selNewLayerStopYear
      cla <- input$selNewLayerClass
      sub <- input$selNewLayerSubClass


      newLayerName <- tolower( paste0(cty,"__",ymn,"_",ymx,"__",cla,"__",sub))
      dataExists <- tolower(newLayerName) %in% tolower(mxReact$layerList)

      valid = FALSE
      if(dataExists){
        outTxt = (sprintf("<b style=\"color:#FF0000\">(taken)</b> %s",newLayerName))
        valid = FALSE
      }else{
        outTxt = (sprintf("<b style=\"color:#00CC00\">(ok)</b> %s",newLayerName))
        valid = TRUE
      }

      output$newLayerNameValidation = renderUI(HTML(outTxt))
      mxActionButtonState(id='fileNewLayer',disable=!valid) 

      mxReact$newLayerName <- ifelse(valid,newLayerName,"")

    })


    #
    #  FILE HANDLER : VALIDATION AND PSQL 
    #


    observeEvent(input$fileNewLayer,{
      dat = input$fileNewLayer
      nam = mxReact$newLayerName 
      if(noDataCheck(nam)){
        message(paste("New layer upload requested, but no name available"))
        return()
      }

      lInfo = ogrinfo(dat$datapath,ro=TRUE)
      if(length(grep("OGRGeoJSON",lInfo)[1]) < 1 ){
        message("Data imported is not in format 'geojson'")
        return()
      }

      lInfo = ogrinfo(dat$datapath,"OGRGeoJSON",ro=TRUE,so=TRUE)

      # check if the data is SRID is 4326 TODO: see if the method could be less fragile
      projOk = length(grep("(AUTHORITY).+(EPSG).+(4326)",lInfo)) > 0 && length(grep("(GEOGCS).*(WGS 84)",lInfo)) >0

      # send data directly to postgis
      if(projOk){
        d <- dbInfo
        dst <- sprintf("PG:dbname='%s' host='%s' port='%s' user='%s' password='%s'",
          d$dbname,d$host,d$port,d$user,d$password
          )
        src = dat$datapath

        # NOTE : no standard method worked.
        # rgdal::writeOGR (require loading in r AND did not provide options AND did not allow mixed geometry) or gdalUtils::ogr2ogr failed (did not set -f option!).
        cmd = sprintf(
          "ogr2ogr
          -t_srs 'EPSG:4326'
          -s_srs 'EPSG:4326'
          -geomfield geom
          -lco FID=gid
          -lco GEOMETRY_NAME=geom
          -lco SCHEMA=public
          -f 'PostgreSQL'
          -overwrite
          -nln '%s'
          '%s'
          '%s'
          ",nam,dst,src)
          cmd <- gsub("\\n","",cmd)
          er = system(cmd,intern=TRUE)


          tryCatch({
            # update db if expire and octroyé column exist
            d <- dbInfo
            drv <- dbDriver("PostgreSQL")
            con <- dbConnect(drv, dbname=d$dbname, host=d$host, port=d$port,user=d$user, password=d$password)

            cols <- dbListFields(con,nam)

            if(! 'mx_date_end' %in% cols && ! 'mx_date_start' %in% cols ){
              if('octroyé' %in% cols && 'expire' %in% cols){
                # TODO: drop old column, validate date formating.
                # add columns
                qAdd = sprintf("ALTER TABLE %s ADD mx_date_start bigint, ADD mx_date_end bigint;",nam)
                dbGetQuery(con,qAdd)
                # update date start
                qStart = sprintf("UPDATE %s SET mx_date_start = extract(epoch from to_timestamp(octroyé,'YYYY/MM/DD'));",nam)
                dbGetQuery(con,qStart)
                # update date end
                qEnd = sprintf("UPDATE %s SET mx_date_end = extract(epoch from to_timestamp(expire,'YYYY/MM/DD'));",nam)
                dbGetQuery(con,qEnd)
              }

            }
          },finally={if(exists('con')){dbDisconnect(con)}}
            )


          if(mxConfig$os=="Darwin"){
            # note: use ssh-copy-id and accept known host. Use the browser the first time...
            # TODO: create a method to avoid this !
            if(!exists('remoteInfo'))stop("No remoteInfo found in /settings/settings.R")
            r <- remoteInfo 
            mxDebugMsg("Command remote server to restart app")
            remoteCmd(host=r$host,port=r$port,user=r$user,cmd=mxConfig$restartPgRestApi)
          }else{
            system(mxConfig$restartPgRestApi)
          }
          mxDebugMsg("invalidate layer list")
          mxReact$layerListUpdate <- runif(1)
      }else{
        msgList <- paste("Error before importation. projOk=",projOk,"ellpsOk=",ellpsOk)
        output$newLayerNameValidation = renderUI(HTML(msgList))
      }      
    })


        observeEvent(input$btnViewsRefresh,{


          if(mxConfig$os=="Darwin"){
            print("update pgrestapi from darwin")
            # note: use ssh-copy-id and accept known host. Use the browser the first time...
            # TODO: create a method to avoid this !
            if(!exists('remoteInfo'))stop("No remoteInfo found in /settings/settings.R")
            r <- remoteInfo 
            mxDebugMsg("Command remote server to restart app")
            remoteCmd("map-x-full",cmd=mxConfig$restartPgRestApi)
          }else{
            print("update pgrestapi from not darwin")
            system(mxConfig$restartPgRestApi)
          }

          mxReact$layerListUpdate <- runif(1)    
    })



        #
        # Populate layer selection
        #
        observe({
          # default
          choice <- mxConfig$noData
          # take reactivity on select input

          cntry <- tolower(mxReact$selectCountry)
          # reactivity after updateVector in postgis
          update <- mxReact$layerListUpdate

          # mxCatch("Update input: pgrestapi layer list",{
          layers <- vtGetLayers(port=mxConfig$portVt,grepExpr=paste0("^",cntry,"_"))
          if(!noDataCheck(layers)){
            choice = c(choice,layers)  
          }
          updateSelectInput(session,"selLayer",choices=choice)
          mxReact$layerList = choice
          #   })
        })


        #
        # Populate column selection
        # 

        observe({
          mxCatch("Update input: layer columns",{
            vars = mxConfig$noData
            lay = input$selLayer
            if(!noDataCheck(lay)){
              variables <- vtGetColumns(table=lay,port=mxConfig$portVt,exclude=c("geom","gid"))$column_name
              if(!noDataCheck(variables)){
                vars = variables
              } 
            }
            if("mx_date_start" %in% vars && "mx_date_end" %in% vars){
              tryCatch({
                d <- dbInfo
                drv <- dbDriver("PostgreSQL")
                con <- dbConnect(drv, dbname=d$dbname, host=d$host, port=d$port,user=d$user, password=d$password)
                q <- sprintf("SELECT min(mx_date_start),max(mx_date_end) FROM %s;",lay)
                mxDate <- dbGetQuery(con,q)
                mx <- as.Date(as.POSIXct(max(mxDate), origin="1970-01-01"))
                mn <- as.Date(as.POSIXct(min(mxDate), origin="1970-01-01"))
                updateDateRangeInput(session,"mapViewDateRange",start=mn,end=mx)
              },finally={if(exists('con'))dbDisconnect(con)}
                )
              mxStyle$hasDateColumns = TRUE
            }else{ 
              updateDateRangeInput(session,"mapViewDateRange",start=mxConfig$minDate,end=mxConfig$maxDate)
              mxStyle$hasDateColumns = FALSE
            }

            updateSelectInput(session, "selColumnVar", choices=vars)
            updateSelectInput(session, "selColumnVarToKeep", choices=c(vars,mxConfig$noVariable),selected=vars[1])
            })
        })


        #
        # get selected variable summary and populate palette input
        #

        observe({
          lay = input$selLayer
          var = input$selColumnVar
          isolate({
            if(!noDataCheck(lay) && !noDataCheck(var)){
              layerSummary <- dbGetColumnInfo(dbInfo,lay,var)
              if(noDataCheck(layerSummary)){
                return(NULL)
              }
              type <- layerSummary$scaleType
              #  if(type == "continuous"){
              #    paletteChoice <- mxConfig$colorPalettesContinuous
              #  }else{
              #    paletteChoice<- mxConfig$colorPalettesDiscrete
              #  }
              paletteChoice <- mxConfig$colorPalettes
              mxStyle$scaleType <- layerSummary$scaleType
              mxStyle$values <- layerSummary$dValues
              mxStyle$nDistinct <- layerSummary$nDistinct
              mxStyle$nMissing <- layerSummary$nNa
              mxStyle$paletteChoice <- paletteChoice

              updateSelectInput(session,"selPalette",choices=paletteChoice)
              #mxDebugMsg('Set layer summary')
            }
          })
        })


        #
        # Set layer options based on inputs
        #


        observe({
          mxStyle$title <- if(!noDataCheck(input$mapViewTitle)) input$mapViewTitle 
        })

        observe({
          mxStyle$layer <-if(!noDataCheck(input$selLayer))input$selLayer
        })

        observe({
          mxStyle$variable <- if(!noDataCheck(input$selColumnVar))input$selColumnVar
        })
   

        observe({
          mxStyle$palette  <- if(!noDataCheck(input$selPalette))input$selPalette
        })

        observe({
          mxStyle$opacity <- if(!noDataCheck(input$selOpacity))input$selOpacity
        })

        observe({
          mxStyle$basemap <- if(!noDataCheck(input$selectBaseMap))input$selectBaseMap
        })

        observe({
          mxStyle$size <- if(!noDataCheck(input$selSize))input$selSize
        })

        observe({
          mxStyle$hideLabels <- if(!noDataCheck(input$checkBoxHideLabels))input$checkBoxHideLabels
        })

        observe({
          mxStyle$hideLegends <- if(!noDataCheck(input$checkBoxHideLegends)) input$checkBoxHideLegends 
        })


        observe({
          dRange <- input$mapViewDateRange
          if(isTRUE(length(dRange)==2)){
            mxStyle$mxDateMin <- min(dRange)
            mxStyle$mxDateMax <- max(dRange)
          }
        })


        #
        # Set current group.
        #
        observe({
          mxStyle$group = mxConfig$defaultGroup
        })

        #
        # SAVE STYLE
        # 

        observeEvent(input$btnMapCreatorSave,{
          browser()
          mxCatch(title="Save style",{
            sty <- reactiveValuesToList(mxStyle)
            # save additional variables
            hasDate <- mxStyle$hasDateColumns
            vToKeep <- input$selColumnVarToKeep
            vToKeep <- vToKeep[!vToKeep %in% mxConfig$noVariable]
            if(hasDate){
              vToKeep <- unique(c("mx_date_start","mx_date_end",vToKeep))
            }
            sty$variableToKeep <- vToKeep
            # save has date state
            sty$hasDateColumns <- hasDate
           
            sty$hasCompanyColumn <- isTRUE('parties' %in% vToKeep)

            tableName <- mxConfig$viewsListTableName

            d <- dbInfo
            drv <- dbDriver("PostgreSQL")
            con <- dbConnect(drv, dbname=d$dbname, host=d$host, port=d$port,user=d$user, password=d$password)

            tryCatch({
              tableAppend = isTRUE( tableName %in% dbListTables(con))
              tbl = as.data.frame(stringsAsFactors=FALSE,list(
                  id =  randomName(),
                  country = mxReact$selectCountry,
                  title = input$mapViewTitle,
                  class = input$mapViewClass,
                  layer = sty$layer,
                  editor = mxReact$userName,
                  reviever = "",
                  revision = 0,
                  validated = TRUE,
                  archived = FALSE,
                  dateCreated = date(),
                  dataModifed = date(),
                  dateValidated = date(),
                  dateVariableMax = max(input$mapViewDateRange),
                  dateVariableMin = min(input$mapViewDateRange),
                  style = toJSON(sty,collapse="")
                  )
                )
              dbWriteTable(con,tableName,value=tbl,append=tableAppend,row.names=F)
            },finally=dbDisconnect(con)
            )

            mxDebugMsg(sprintf("Write style %s in table %s", tbl$id, tbl$layer))
            mxReact$viewsListUpdate <- runif(1)
            output$txtValidationCreator = renderText({"ok."})
          })
        })




  }
})
