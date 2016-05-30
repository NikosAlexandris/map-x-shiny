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
    grp <- mxStyle$group
    lay <- mxStyle$layer

    feedBack <- "once"
    mapViewMode <- isolate(mxReact$mapPanelMode) 

    if(is.null(mapViewMode)){
      mapViewMode="mapViewsExplorer"
    }

    if(!noDataCheck(lay)){
      mxDebugMsg(paste("Ready to add vector tiles",lay," in group",grp))
      isolate({
        
        var <- mxStyle$variable
        varToKeep <- mxStyle$variableToKeep
        varStored <- mxDbGetColumnsNames(lay)

        if(mapViewMode == "mapViewsCreator"){
          # In creator mode, get all the variables 
          feedback <- "always"
          vars <- varStored
        }else{
          # Other mode, only get variables kept
          vToKeep <- mxStyle$variableToKeep
          vToKeep <- vToKeep[!vToKeep %in% mxConfig$noVariable]
          vars <- unique(c(var,vToKeep))
          vars <- vars[vars %in% varStored]
          feedback <- "once"
        }
      })

      if(!noDataCheck(vars)){
      
        proxyMap <- leafletProxy("mapxMap",deferUntilFlush=FALSE)

        proxyMap %>%
        clearGroup(grp)

      proxyMap %>%
        addVectorTiles(
          userId         = mxReact$userInfo$id,
          protocol       = mxConfig$vtInfo$protocol,
          host           = mxConfig$vtInfo$host,
          port           = mxConfig$vtInfo$port,
          geomColumn     = mxConfig$vtInfo$geom,
          idColumn       = mxConfig$vtInfo$gid,
          layer          = lay,
          dataColumn     = vars,
          group          = grp,
          onLoadFeedback = feedback
          )  

        mxDebugMsg(paste("Start downloading",lay,"from host",mxConfig$vtInfo$host,"on port:",mxConfig$vtInfo$port))

      }
    }
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
    vData <- mxReact$views
    # don't do anything if id and layer are empty
    if(isTRUE(!noDataCheck(grp) && !noDataCheck(lay))){
      # Message about the feedback
      mxDebugMsg(sprintf("Tiles feedback grp='%1$s',lay='%2$s'",grp,lay))
      # get the style for the given group
      sty <- vData[[grp]]$style
      # handle other varables. As it's new feature, old views don't have this.
      vToKeep <- sty$variableToKeep
      if(is.null(vToKeep))vToKeep <- mxConfig$noVariable
      if(mxReact$mapPanelMode=="mapViewsStory"){
        baseMap <- sty$basemap
      }else{
        baseMap <- mxConfig$noLayer
      }

      # after validation
      if(!noDataCheck(sty)){
        mxStyle$scaleType      <- sty$scaleType
        mxStyle$title          <- sty$title
        mxStyle$variable       <- sty$variable
        mxStyle$variableToKeep <- vToKeep
        mxStyle$values         <- sty$values
        mxStyle$palette        <- sty$palette
        mxStyle$paletteChoice  <- mxConfig$colorPalettes
        mxStyle$opacity        <- sty$opacity
        mxStyle$basemap        <- baseMap
        mxStyle$size           <- sty$size
        mxStyle$hideLabels     <- sty$hideLabels
        mxStyle$hideLegends    <- sty$hideLegends
      }
    }
})
})

#
# Set map center based on center of layer
#

observeEvent(input$btnZoomToLayer,{
  if(noDataCheck(mxReact$selectCountry))return()
  mxCatch(title="Btn zoom to layer",{
    lay <- mxStyle$layer
    if(noDataCheck(lay))return()
    zm <- mxConfig$countryCenter[[mxReact$selectCountry]]$zoom
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
    initOk <- isTRUE(mxReact$mapInitDone > 0)

    glOk <- isTRUE(input$glLoaded == "basemap")

    if(initOk && glOk ){
      proxymap <- leafletProxy("mapxMap")
      styleList = list(
        mapboxsat  = list(
          `id` = 'rasterOverlay',
          `source` = 'mapboxsat',
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
      if( selBaseMap != mxConfig$noLayer ){    
        proxymap %>% 
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
    if(noDataCheck(mxReact$selectCountry))return()
    mxCatch(title="Set layer labels",{
      group = "labels"
      hideLabels <- mxStyle$hideLabels
      iso3 <- mxReact$selectCountry
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
    # and if they correspond to mxStyle
    grpLocal <- mxStyle$group
    layLocal <- mxStyle$layer
    grpClient <- input$leafletvtIsLoaded$grp
    layClient <- input$leafletvtIsLoaded$lay

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
          sty <- reactiveValuesToList(mxStyle)
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
      sty = layerStyle() 
      if(!noDataCheck(sty)){
        mxSetStyle(style=sty)
      }
          })
  })
