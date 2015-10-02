#
# Add vector tiles with selected variables
#

observe({ 
  mxCatch(title="Add vector tiles",{
    grp <- mxStyle$group
    lay <- mxStyle$layer

    mapViewMode <- isolate(mxReact$mapPanelMode) 
    if(is.null(mapViewMode))mapViewMode="mapViewsExplorer" # TODO: set default for mxReact$mapPanelMode 
    if(!noDataCheck(lay)){
      mxDebugMsg(paste("Ready to add vector tiles",lay," in group",grp))
      isolate({
        var <- mxStyle$variable 
        if(mapViewMode == "mapViewsCreator"){
          vars <- vtGetColumns(table=lay,port=mxConfig$portVt)$column_name
        }else{
          vToKeep <- mxStyle$variableToKeep
          vToKeep <- vToKeep[!vToKeep %in% mxConfig$noVariable]
          vars <- unique(c(var,vToKeep))
        }
      })
      if(!noDataCheck(vars)){
        proxyMap <- leafletProxy("mapxMap")
        proxyMap %>%
        clearGroup(mxConfig$defaultGroup)

        proxyMap %>%
        addVectorTiles(
          url=mxConfig$hostVt,
          port=mxConfig$portVtPublic,
          geomColumn="geom", # should be auto resolved by PGRestAPI
          idColumn="gid", # should be auto resolved by PGRrestAPI
          table=lay,
          dataColumn=vars,
          group = grp
          )  
        mxDebugMsg(paste("Start downloading",lay,"from host",mxConfig$hostVt,"on port:",mxConfig$portVt))
      }
    }
})
})



#
# MESSAGE FROM CLIENT : TILES ARE LOADED, DO SOMETHING
#

observeEvent(input$leafletvtStatus,{
  mxCatch(title="Set style object after tiles loaded",{

    lay <- input$leafletvtStatus$lay
    grp <- input$leafletvtStatus$grp
    vData <- mxReact$views

    if(isTRUE(!noDataCheck(grp) && !noDataCheck(lay))){
      sty <- vData[[grp]]$style
      if(!noDataCheck(sty)){

        mxStyle$scaleType <- sty$scaleType
        mxStyle$title <- sty$title
        mxStyle$variable <- sty$variable
        # handle other varables. As it's new feature, old views don't have this.
        vToKeep <- sty$variableToKeep 
        if(is.null(vToKeep))vToKeep=mxConfig$noVariable
        #as we check for null in layerStyle(),add "noData/noVariable" values..
        mxStyle$variableToKeep = vToKeep

        mxStyle$values <- sty$values
        mxStyle$palette <- sty$palette
        mxStyle$paletteChoice <-  mxConfig$colorPalettes
        mxStyle$opacity <- sty$opacity
        if(mxReact$mapPanelMode=="mapViewsStory"){
          mxStyle$basemap <- sty$basemap
        }else{
          mxStyle$basemap <- mxConfig$noLayer
        }
        mxStyle$size <- sty$size
        mxStyle$hideLabels <- sty$hideLabels
        mxStyle$hideLegends <- sty$hideLegends
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

observeEvent(input$linkSetWmsExampleColumbia,{
  updateTextInput(session,"txtWmsServer",value="http://sedac.ciesin.columbia.edu/geoserver/wms")
})



observeEvent(input$linkSetWmsExampleGrid,{
  updateTextInput(session,"txtWmsServer",value="http://preview.grid.unep.ch:8080/geoserver/wms")
})






observeEvent(input$btnValidateWms,{
  mxCatch(title="WMS server",{
    wmsServer <- input$txtWmsServer
    if(!noDataCheck(wmsServer)){

      req="?service=WMS&request=GetCapabilities"
      req <- paste0(wmsServer,req)

      cachedRequest<-mxReact$wmsRequest[[wmsServer]]

      if(noDataCheck(cachedRequest)){ 
        dat <- XML::xmlToList(req)
        mxReact$wmsRequest[[wmsServer]] <- dat
      }else{
        dat <- cachedRequest 
      }
      res=list()
      layers <- dat[['Capability']][['Layer']]
      layLength <- length(layers)
      for(i in 1:layLength){
        if(names(layers[i])=="Layer"){
          # legends : Layers[i]$Layer$Style$LegendURL
          res[layers[i]$Layer$Title]<-i
        }
      }
      updateSelectInput(session,'selectWmsLayer',choices=res,selected=res[1])
    }
})
})


observe({
  mxCatch(title="Add wms layer",{
    layerId = "wmslayer"
    lay <- input$selectWmsLayer
    url <- input$txtWmsServer
    if(!noDataCheck(lay) && !noDataCheck(url)){
      isolate({
        dat<-mxReact$wmsRequest[[url]][['Capability']][['Layer']][[as.numeric(lay)]]
        proxyMap <- leafletProxy("mapxMap")
        proxyMap %>% addWMSTiles(
          layerId=layerId,
          baseUrl=url,
          layers=dat$Name,
          options=list(
            "transparent"="true",
            "format"="image/png8",
            "zIndex"=-1
            )
          )

    })}
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
  mxCatch(title="Set layerStyle()",{
    # check if vector tiles are loaded 
    # and if they correspond to mxStyle

    grpLocal <- mxStyle$group
    layLocal <- mxStyle$layer
    grpClient <- input$leafletvtStatus$grp
    layClient <- input$leafletvtStatus$lay
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
  sty = layerStyle() # NOTE: Why this reactiv function invalidate the observer ?
  if(!noDataCheck(sty)){
    mxDebugMsg(paste("layerStyle() received for",sty$group))
    mxSetStyle(style=sty)
  }
})
