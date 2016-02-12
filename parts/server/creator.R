#                             
#  _ __ ___   __ _ _ __   __  __
# | '_ ` _ \ / _` | '_ \  \ \/ /
# | | | | | | (_| | |_) |  >  < 
# |_| |_| |_|\__,_| .__/  /_/\_\
#                 | |           
#                 |_|           
# view creator management


observe({
  if(mxReact$allowViewsCreator){
    class = input$selNewLayerClass
    if(!noDataCheck(class)){
      updateSelectInput(session,"selNewLayerSubClass",choices=mxConfig$subclass[[class]])
    }
  }
})



# new layer name validation

observe({
  if(mxReact$allowViewsCreator){
    err = character(0)
    info = character(0)
    out  = character(0)
    valid = FALSE
    msgList = character(0)


    #
    # Layer name warning
    #
    cty <- mxReact$selectCountry
    yea <- input$selNewLayerYear
    cla <- input$selNewLayerClass
    sub <- subPunct(input$txtNewLayerTags)
    atr <- input$txtNewLayerAttribution
    des <- input$txtNewLayerDescription

    newLayerName <- tolower( paste0(cty,"__",yea,"__",cla,"__",sub))

    exist <- mxTextValidation(
      textToTest = newLayerName,
      existingTexts = mxReact$layerList,
      idTextValidation = "outNewLayerNameValidation",
      existsText = "overwrite",
      errorColor = "#ff9900"
      )

    #
    # other validation
    #


    tagMissing <- nchar(sub) < 2
    attrMissing <-  nchar(atr) < 2
    descMissing <-  nchar(des) < 10

    if(tagMissing) err <- c(err,"Tag(s) missing")
    if(attrMissing) err <- c(err,"Source(s) missing")
    if(descMissing) err <- c(err,"Description missing")


 if(length(err)>0){
    outTxt = sprintf("<b style=\"color:%1$s\">(%2$s)</b> %3$s","#FF0000","Issue: ",err,"</br>")
    outTxt = paste("<ul class='nav'>",paste("<li>",outTxt,"</li>"),"</ul>")
    valid = FALSE
  }else{
    outTxt = ""
    valid = TRUE
  }

  mxUpdateText(id="outNewLayerErrors",text=HTML(outTxt))

    mxActionButtonState(id="fileNewLayer",disable=!valid, warning=!exist) 

    mxReact$newLayerName <- ifelse(valid,newLayerName,"")
  }
})


#
#  FILE HANDLER : VALIDATION AND PSQL 
#


observeEvent(input$fileNewLayer,{

  if(mxReact$allowViewsCreator){



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

          if(! "mx_date_end" %in% cols && ! "mx_date_start" %in% cols ){
            if("octroyé" %in% cols && "expire" %in% cols){
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
        },finally={if(exists("con")){dbDisconnect(con)}}
          )


        if( mxConfig$hostname != "map-x-full" ){
          if(!exists("remoteInfo"))stop("No remoteInfo found in /settings/settings.R")
          r <- remoteInfo 
          mxDebugMsg("Command remote server to restart app")
          remoteCmd(host="map-x-full",cmd=mxConfig$restartPgRestApi)
        }else{
          system(mxConfig$restartPgRestApi)
        }
        mxDebugMsg("invalidate layer list")
        mxReact$layerListUpdate <- runif(1)
    }else{
      msgList <- paste("Error before importation. projOk=",projOk,"ellpsOk=",ellpsOk)
      output$newLayerNameValidation = renderUI(HTML(msgList))
    }
  }
})

      observeEvent(input$btnViewsRefresh,{
        if(mxReact$allowViewsCreator){
          if(mxConfig$os=="Darwin"){
            print("update pgrestapi from darwin")
            if(!exists("remoteInfo"))stop("No remoteInfo found in /settings/settings.R")
            r <- remoteInfo 
            mxDebugMsg("Command remote server to restart app")
            remoteCmd("map-x-full",cmd=mxConfig$restartPgRestApi)
          }else{
            print("update pgrestapi from not darwin")
            system(mxConfig$restartPgRestApi)
          }

          mxReact$layerListUpdate <- runif(1) 
        }
})



      #
      # Populate layer selection
      #
      observe({
        if(mxReact$allowViewsCreator){
          # default
          choice <- mxConfig$noData
          # take reactivity on select input

          cntry <- tolower(mxReact$selectCountry)
          # reactivity after updateVector in postgis
          update <- mxReact$layerListUpdate

          mxCatch("Update input: pgrestapi layer list",{
            layers <- vtGetLayers(port=mxConfig$portVt,grepExpr=paste0("^",cntry,"_"))
            if(!noDataCheck(layers)){
              choice = c(choice,layers)  
            }
            updateSelectInput(session,"selLayer",choices=choice)
            mxReact$layerList = choice
          })
        }
      })


      #
      # Populate column selection
      # 

      observeEvent(input$selLayer,{
        if(mxReact$allowViewsCreator){
          # take reactivity on layer selection
          lay = input$selLayer
          # Default variables
          vars = mxConfig$noData
          # check if it has date cols
          hasDate = FALSE
          # if layer is not empty:
          # - get available variables
          # - check for map x dates variables
          # - save in mxStyle
          # - update select input with available variable

          if(!noDataCheck(lay)){
            mxCatch("Update input: layer columns",{
              variables <- vtGetColumns(table=lay,port=mxConfig$portVt,exclude=c("geom","gid"))$column_name
              mxDebugMsg(sprintf("Creator. variable available for %1$s : %2$s",lay,paste(variables,collapse=",")))
              if(!noDataCheck(variables)){
                vars = variables
              } 
              # Date handling 
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
                },finally={if(exists("con"))dbDisconnect(con)}
                  )
                hasDate <- TRUE
              }else{ 
                updateDateRangeInput(session,"mapViewDateRange",start=mxConfig$minDate,end=mxConfig$maxDate)
                hasDate <- FALSE
              }

          })
            # Set mxStyle
            mxStyle$layer <- lay
            mxStyle$group <- mxConfig$defaultGroup
            mxStyle$hasDateColumns <- hasDate
          }

          # NOTE: bug with code and parties. After code, no variable can be set on extractive mineral layer 
          varsLess <- vars[!vars %in% c("code","parties")]
          updateSelectInput(session, "selColumnVar", choices=varsLess)
          updateSelectInput(session, "selColumnVarToKeep", choices=c(vars,mxConfig$noVariable),selected=vars[1])
        }
      })


      #
      # get selected variable summary, set mxStyle accordingly and update palette choice.
      #

      observeEvent(input$selColumnVar,{
        if(mxReact$allowViewsCreator){
          lay = input$selLayer
          var = input$selColumnVar
          isolate({
            if(!noDataCheck(lay) && !noDataCheck(var)){
              # extract layer summary from postgres
              layerSummary <- dbGetColumnInfo(dbInfo,lay,var)
              if(noDataCheck(layerSummary)){
                return(NULL)
              }
              # set palette choice
              paletteChoice         <- mxConfig$colorPalettes
              updateSelectInput(session,"selPalette",choices=paletteChoice)
              # From now, we have enough info to begin mxStyle setting.
              mxStyle$variable      <- var
              mxStyle$scaleType     <- layerSummary$scaleType
              mxStyle$values        <- layerSummary$dValues
              mxStyle$nDistinct     <- layerSummary$nDistinct
              mxStyle$nMissing      <- layerSummary$nNa
              mxStyle$paletteChoice <- paletteChoice
                          }
          })
        }
      })


      #
      # Set other layer options based on inputs
      #


      observe({
        mxStyle$title <- if(!noDataCheck(input$mapViewTitle)) input$mapViewTitle 
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
        mxStyle$variableUnit <- input$txtVarUnit
      })



      observe({
        dRange <- input$mapViewDateRange
        if(isTRUE(length(dRange)==2)){
          mxStyle$mxDateMin <- min(dRange)
          mxStyle$mxDateMax <- max(dRange)
        }
      })


 

      #
      # SAVE STYLE
      # 

      observeEvent(input$btnMapCreatorSave,{
        if(mxReact$enableViewsCreator){
          mxCatch(title="Save style",{
            #sty2<-layerStyle()
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

            sty$hasCompanyColumn <- isTRUE("parties" %in% vToKeep)

            tableName <- mxConfig$viewsListTableName

            sty$description <- input$txtViewDescription


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
                  editor = mxReact$userId,
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
        }
      })

