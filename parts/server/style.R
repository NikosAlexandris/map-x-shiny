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
        if(mapViewMode == "mapViewsCreator"){
         # In creator mode, get all the variables 
          vars <- vtGetColumns(table=lay,port=mxConfig$portVt)$column_name
          feedBack <- "always"
          #feedBack <- "once" # input$leafletvtLoaded will not be triggered more than once 
        }else{
          # Other mode, only get variables kept
          vToKeep <- mxStyle$variableToKeep
          vToKeep <- vToKeep[!vToKeep %in% mxConfig$noVariable]
          vars <- unique(c(var,vToKeep))
          feedBack <- "once"
        }
      })
      if(!noDataCheck(vars)){
        proxyMap <- leafletProxy("mapxMap")

        proxyMap %>%
        clearGroup(mxConfig$defaultGroup)

        proxyMap %>%
        addVectorTiles(
          url            = mxConfig$hostVt,
          port           = mxConfig$portVtPublic,
          geomColumn     = "geom",
          idColumn       = "gid",
          table          = lay,
          dataColumn     = vars,
          group          = grp,
          onLoadFeedback = feedBack
          )  
        mxDebugMsg(paste("Start downloading",lay,"from host",mxConfig$hostVt,"on port:",mxConfig$portVt))
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
    zm = mxConfig$countryCenter[[mxReact$selectCountry]]$zoom
    centro<-dbGetLayerCentroid(dbInfo=dbInfo,table=lay)
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
    layId = "basemap"
    selBaseMap <- mxStyle$basemap 
    selBaseMapGlobal <- input$selectConfigBaseMap
    if(isTRUE(!selBaseMapGlobal == mxConfig$noLayer)) selBaseMap = selBaseMapGlobal
    if(noDataCheck(selBaseMap)) return()
    proxyMap <- leafletProxy("mapxMap")

    if(selBaseMap==mxConfig$noLayer){
      mxDebugMsg("Remove additional base layer if needed")
      proxyMap %>%
      removeTiles(layerId=layId)
    }else{
      if(! selBaseMap == "mapbox"){
        proxyMap %>%
        removeTiles(layId) %>%
        addProviderTiles(selBaseMap,layerId=layId,options=list('zIndex'=0))
      }else{
        proxyMap %>%
        removeTiles(layId) %>%
        addTiles(
          "https://api.mapbox.com/v4/mapbox.satellite/{z}/{x}/{y}.png?access_token=pk.eyJ1IjoiaGVsc2lua2kiLCJhIjoiMjgzYWM4NTE0YzQyZGExMTgzYTJmNGIxYmEwYTQwY2QifQ.dtq8cyvJFrJSUmSPtB6Q7A"
          ,layerId=layId,options=list('zIndex'=-4))
      }
    }
})
})



observeEvent(input$btnRemoveBaseMap,{
  layerId <- "basemap"
  proxyMap <- leafletProxy("mapxMap")
  proxyMap %>% removeTiles(layerId)
})





#
# Additional WMS map
#



observe({
updateTextInput(session,inputId="txtWmsServer",value=input$selectWmsServer)
})



#' Get list of available layers and name.
#' @param getCapabilitiesList List that contains a list of a parsed GetCapabilities on a wms server (esri or ogc should work)
mxGetWmsLayers <- function(getCapabilitiesList){
  dat <- getCapabilitiesList
  if(class(dat) != "list"){
    stop("mxGetWmsLayers expects a list")
  }
  layers <- dat[['Capability']][['Layer']]
  layers <- layers[names(layers)=="Layer"]
  nLayer <- length(layers)
  res <- list()
  for(i in 1:nLayer){
    j <- layers[[i]]
    k <- j[names(j) == "Layer"]
    n <- length(k)
    ln <- j[['Name']]
    lt <- na.omit(j[['Title']])
    if(n>0){
      for(l in 1:n){
        kn <- k[[l]][['Name']]
        if(!is.null(kn)){
          ln<-c(ln,kn)
        }
      }
    }
    ln<-paste(ln,collapse=",")
    if(!isTRUE(nchar(lt)>0)){
      ln <-paste("[ no title ", randomName()," ]",sep="")
    }
    if(isTRUE(nchar(ln)>0)){
      res[lt]<-ln
    }
  }
  return(res)
}


observeEvent(input$btnValidateWms,{
  mxCatch(title="WMS server",{
    wmsServer <- input$txtWmsServer
    if(!noDataCheck(wmsServer)){

#      wmsServer="http://mesonet.agron.iastate.edu/cgi-bin/wms/nexrad/n0r.cgi"
 #     wmsServer="http://nowcoast.noaa.gov/arcgis/services/nowcoast/analysis_meteohydro_sfc_qpe_time/MapServer/WmsServer"
      req="?service=WMS&request=GetCapabilities"
      req <- paste0(wmsServer,req)

      cachedRequest<-mxReact$wmsRequest[[wmsServer]]

      if(noDataCheck(cachedRequest)){ 

        pars <- XML::xmlParse(req,options=XML::NOCDATA) 
        dat <- XML::xmlToList(pars)

        mxReact$wmsRequest[[wmsServer]] <- dat
      }else{
        dat <- cachedRequest 
      }
  

      res = mxGetWmsLayers(dat)

      updateSelectInput(session,'selectWmsLayer',choices=res,selected=res[1])
    }
})
})


observeEvent(input$selectWmsLayer,{
  mxCatch(title="Add wms layer",{
    layerId = "wmslayer"
    lay <- input$selectWmsLayer
    url <- input$txtWmsServer

    if(!noDataCheck(lay) && !noDataCheck(url)){

      proxyMap <- leafletProxy("mapxMap")
      proxyMap %>% addWMSTiles(
        layerId=layerId,
        baseUrl=url,
        layers=lay,
        options=list(
          "transparent"="true",
          "format"="image/png8",
          "zIndex"=-1
          )
        )

    }
})
})


observeEvent(input$btnRemoveWms,{
    layerId = "wmslayer"
   proxyMap <- leafletProxy("mapxMap")
    proxyMap %>% removeTiles(layerId)
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
        layClient == sprintf("%s_%s",layLocal,mxConfig$defaultGeomCol)
        ){
        sty <- reactiveValuesToList(mxStyle)
        if(!any(sapply(sty,is.null))){
          palOk <- isTRUE(sty$palette %in% sty$paletteChoice)
          if(palOk){ 
            sty <- addPaletteFun(sty,sty$palette)
            sty$colors <- sty$paletteFun(sty$values)
            return(sty)
          }
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
    sty = layerStyle() # NOTE: Why this reactiv function invalidate the observer ?
    if(!noDataCheck(sty)){
      mxSetStyle(style=sty)
    }
})
})
