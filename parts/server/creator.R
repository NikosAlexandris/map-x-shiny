  observe({

  if(isTRUE(mxReact$mapPanelMode == "mapViewsCreator")){

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


      newLayerName <- tolower( paste0(cty,"__",ymn,"_",ymx,"__",cla,"_",sub))
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
     mxActionButtonToggle(id='fileNewLayer',disable=!valid) 

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

        # NOTE : no standard metod worked.
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
          -nln '%s'
          '%s'
          '%s'
          ",nam,dst,src)
          cmd <- gsub("\\n","",cmd)
          er = system(cmd,intern=TRUE)


          # note: use ssh-copy-id and accept known host. Use the browser the first time...
          # TODO: create a method to avoid this !
          r <- remoteInfo
      mxDebugMsg("Command to remote server to restart app")
          remoteCmd(host=r$host,port=r$port,user=r$user,cmd=mxConfig$restartPgRestApi)
         mxDebugMsg("invalidate layer list")
          mxReact$layerListUpdate <- runif(1)
      }else{
        msgList <- paste("Error before importation. projOk=",projOk,"ellpsOk=",ellpsOk)
        output$newLayerNameValidation = renderUI(HTML(msgList))
      }      
    })


    observeEvent(input$btnViewsRefresh,{
      r <- remoteInfo
      mxDebugMsg("Command to remote server to restart app")
      remoteCmd(host=r$host,port=r$port,user=r$user,cmd=mxConfig$restartPgRestApi)
      mxDebugMsg("invalidate layer list")
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
      #mxDebugMsg("Update layers list")
      
     # mxCatch("Update input: pgrestapi layer list",{
        layers <- vtGetLayers(port=3030,grepExpr=paste0("^",cntry,"_"))
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
          variables <- vtGetColumns(table=lay,port=3030,exclude=c("geom","gid"))$column_name
          if(!noDataCheck(variables)){
            vars = variables
          } 
        }
        updateSelectInput(session, "selColumnVar", choices=vars)
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
    mxCatch(title="Save style",{
      sty <- reactiveValuesToList(mxStyle)
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
            editor = "f@fxi.io",
            reviever = "f@fxi.io",
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
