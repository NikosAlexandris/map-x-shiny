#                             
#  _ __ ___   __ _ _ __   __  __
# | '_ ` _ \ / _` | '_ \  \ \/ /
# | | | | | | (_| | |_) |  >  < 
# |_| |_| |_|\__,_| .__/  /_/\_\
#                 | |           
#                 |_|           
# WMS layer event management 

#' Get list of available layers and name.
#' @param getCapabilitiesList List that contains a list of a parsed GetCapabilities on a wms server (esri or ogc should work)
mxGetWmsLayers <- function(getCapabilitiesList){

  # TODO: check if the structure could be :
  # At each level, if a name and a title are provided, take every nested layers as first layer's component.
  # for now, this works for a 1,2 or 3 levels, but this is empiric.

  dat <- getCapabilitiesList
  if(class(dat) != "list"){
    stop("mxGetWmsLayers failed to analyse the response. Probable cause : A structured document expected of class'list' expected")
  }
  layers <- dat[['Capability']][['Layer']]
  
  layersNested <- layers[names(layers)=="Layer"]


  # if there is only one level of layers, but the layer in a list.
  if(length(layersNested)>0){
    layers <- layersNested 
  }else{
    layers <- list(Layer=layers)
  
  }


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



observe({
updateTextInput(session,inputId="txtWmsServer",value=input$selectWmsServer)
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

observeEvent(input$btnValidateWms,{
  mxCatch(title="WMS server get capabilities",{
    wmsServer <- input$txtWmsServer
    if(!noDataCheck(wmsServer)){

      req <- "?service=WMS&request=GetCapabilities"
      req <- paste0(wmsServer,req)

      cachedRequest <- mxReact$wmsRequest[[wmsServer]]

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

observeEvent(input$btnRemoveWms,{
    layerId = "wmslayer"
   proxyMap <- leafletProxy("mapxMap")
    proxyMap %>% removeTiles(layerId)
})



