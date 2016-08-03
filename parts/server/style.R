#                             
#  _ __ ___   __ _ _ __   __  __
# | '_ ` _ \ / _` | '_ \  \ \/ /
# | | | | | | (_| | |_) |  >  < 
# |_| |_| |_|\__,_| .__/  /_/\_\
#                 | |           
#                 |_|           
# Style management for creator and explorer

#
# Add vector tiles with selected variables
#


observe({ 
  mxCatch(title="Add vector tiles",{
    group <- reactStyle$group
    layer <- reactStyle$layer
    if(noDataCheck(group) || noDataCheck(layer)) return()
    isolate({
      mode <- isolate(reactUi$panelMode)
      variable <- isolate(reactStyle$variable)
      userId <- isolate(reactUser$data$id)
      variableToKeep <- isolate(reactStyle$variableToKeep)
      variableToKeep <- variableToKeep[ !variableToKeep %in% mxConfig$noVariable ]
      # test if the requested layer is allowed 
      #layerOk <- isTRUE( !noDataCheck(layer) && layer %in% reactMap$layerList )
      layerOk <- isTRUE( !noDataCheck(layer) )
      # test the current mode
      modeCreator <- isTRUE( mode == "mxModeToolBox" )
      # test no data in variables
      hasVariable <- !noDataCheck(variable)
      hasVariableToKeep <- !noDataCheck(variableToKeep)

      # Add vector tile
      if( layerOk ){


        # fetch availble variable NOTE: this should be done before
        variableAvailable <- mxDbGetColumnsNames( layer )

        # mode specific values 
        # loading feedback :
        # "once" = only send a feedback once when the layer is fully loaded the first time (normal view)
        # "always" = send a feedback each time layer are loaded (creation mode)

        if( modeCreator ){
          vars <- variableAvailable
          feedback <- "always"
        }else{
          vars <- unique(c(variableToKeep,variable))
          feedback <- "once"
        }

        # check variables
        varIsOk <- isTRUE( !noDataCheck(vars) && all( vars %in% variableAvailable ))

        if(varIsOk){

          mxDebugMsg(sprintf("Begin addition of layer %s in group %s",layer,group))

          proxyMap <- leafletProxy("mapxMap",deferUntilFlush=FALSE)

          proxyMap %>%
            clearGroup(group)

          proxyMap %>%
            addVectorTiles(
              userId         = userId,
              protocol       = mxConfig$vtInfo$protocol,
              host           = mxConfig$vtInfo$host,
              port           = mxConfig$vtInfo$port,
              geomColumn     = mxConfig$vtInfo$geom,
              idColumn       = mxConfig$vtInfo$gid,
              layer          = layer,
              dataColumn     = vars,
              group          = group,
              onLoadFeedback = feedback
              )  

          mxDebugMsg(paste("Start downloading",layer,"from host",mxConfig$vtInfo$host,"on port:",mxConfig$vtInfo$port))

        }
      }
    })
})
})



#
# Message from client : tiles are loaded. 
#

observeEvent(input$leafletvtIsLoaded,{
  mxCatch(title="Set style object after tiles loaded",{
    # Check wich layer and wich group/id is loaded
    lay <- input$leafletvtIsLoaded$lay
    grp <- input$leafletvtIsLoaded$grp
    # get the all stored views info
    vData <- reactMap$viewsData
    # don't do anything if id and layer are empty
    if(isTRUE(!noDataCheck(grp) && !noDataCheck(lay))){
      # Message about the feedback
      mxDebugMsg(sprintf("Tiles feedback grp='%1$s',lay='%2$s'",grp,lay))
      # get the style for the given group
      sty <- vData[[grp]]$style
      # handle other varables. As it's new feature, old views don't have this.
      vToKeep <- sty$variableToKeep
      if(is.null(vToKeep))vToKeep <- mxConfig$noVariable
      if(reactUi$panelMode=="storyMap"){
        baseMap <- sty$basemap
      }else{
        baseMap <- mxConfig$noLayer
      }

      # after validation
      if(!noDataCheck(sty)){
        reactStyle$scaleType      <- sty$scaleType
        reactStyle$title          <- sty$title
        reactStyle$variable       <- sty$variable
        reactStyle$variableToKeep <- vToKeep
        reactStyle$values         <- sty$values
        reactStyle$palette        <- sty$palette
        reactStyle$paletteChoice  <- mxConfig$colorPalettes
        reactStyle$opacity        <- sty$opacity
        reactStyle$basemap        <- baseMap
        reactStyle$size           <- sty$size
        reactStyle$hideLabels     <- sty$hideLabels
        reactStyle$hideLegends    <- sty$hideLegends
      }
    }
})
})

#
# Set map center based on center of layer
#

observeEvent(input$btnZoomToLayer,{
  if(noDataCheck(reactProject$name))return()
  mxCatch(title="Btn zoom to layer",{
    lay <- reactStyle$layer
    if(noDataCheck(lay))return()
    zm <- mxConfig$countryCenter[[reactProject$name]]$zoom
    centro<- mxDbGetLayerCentroid(table=lay)
    if(noDataCheck(centro)){
      centro <- list(lng=0,lat=0)
    }
    proxyMap <- leafletProxy("mapxMap")
    proxyMap %>%
    setView(lng=centro$lng, centro$lat, zm)
})
})






#
# Additional base map
#


observe({
  mxCatch(title="Additional base map",{
    layId <- "basemap"
    selBaseMap <- input$selectConfigBaseMap
    initOk <- isTRUE( reactMap$mapInitDone > 0 )
    isChecked <- isTRUE(input$checkSatellite )
    glOk <- isTRUE(input$glLoaded == "basemap")

    if( initOk && glOk ){
      proxymap <- leafletProxy("mapxMap")
      styleList = list(
        mapboxsat  = list(
          `id` = 'rasterOverlay',
          `source` = 'mapboxsat',
          `type`='raster',
          `min-zoom`=0,
          `max-zoom`=22
          ),
        mapboxsatlive  = list(
          `id` = 'rasterOverlay',
          `source` = 'mapboxsatlive',
          `type`='raster',
          `min-zoom`=0,
          `max-zoom`=22
          ),
        heresat = list(
          `id` = 'rasterOverlay',
          `source` = 'heresat',
          `type`='raster',
          `min-zoom`=0,
          `max-zoom`=22
          )
        )
      if( isChecked ){    
        proxymap %>% 
       glRemoveLayer(
          idGl = "basemap",
          idLayer = "rasterOverlay"
          )%>%
        glAddLayer(
          idGl = "basemap",
          idBelowTo = "contours",
          style = styleList[[selBaseMap]] 
          )     
      }else{
        proxymap %>% 
        glRemoveLayer(
          idGl = "basemap",
          idLayer = "rasterOverlay"
          )  
      }
    }
})
})


  #
  # SET LABELS VISIBILITY
  #

  observe({
    if(noDataCheck(reactProject$name)) return()
    mxCatch(title="Set layer labels",{
      group = "labels"
      hideLabels <- reactStyle$hideLabels
      iso3 <- reactProject$name
      if(!noDataCheck(hideLabels) && !noDataCheck(iso3)){
        proxyMap <- leafletProxy("mapxMap")
        if(!hideLabels){
          mxConfig$labelLayerByCountry(iso3,group,proxyMap) 
        }else{
          proxyMap %>%
          clearGroup(group)
        }
      }
          })
  })

  #
  #  Set layer colors
  #
  layerStyle <- reactive({
    # check if vector tiles are loaded 
    # and if they correspond to reactStyle
    grpLocal <- reactStyle$group
    layLocal <- reactStyle$layer
    grpClient <- input$leafletvtIsLoaded$grp
    layClient <- input$leafletvtIsLoaded$lay

   # mxDebugMsg(sprintf("
        #group reactstyle = %1$s
        #layer reactstyle = %2$s
        #group client = %3$s
        #layer client = %4$s
        #"
        #, grpLocal
        #, layLocal
        #, grpClient
        #, layClient
        #))


    mxCatch(title="Set layerStyle()",{

      if(
        !noDataCheck(grpLocal) && 
        !noDataCheck(grpClient) && 
        !noDataCheck(layLocal) && 
        !noDataCheck(layClient)
        ){
        if(
          grpClient == grpLocal && 
          layClient == layLocal
          ){
          sty <- reactiveValuesToList(reactStyle)
          palOk <- isTRUE(sty$palette %in% sty$paletteChoice)
          if(palOk){ 
            sty <- addPaletteFun_cache(sty,sty$palette)
            sty$colors <- sty$paletteFun(sty$values)
            return(sty)
          }
        }
      }
      return(NULL)
          })
  })


  #
  # FINAL STEP TO SET STYLE
  #

  observe({
    mxCatch(title="Apply layerStyle()",{
      sty <- layerStyle() 
      if(!noDataCheck(sty)){

        mxSetStyle(style=sty)
      }
          })
  })
