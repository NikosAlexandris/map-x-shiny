#                             
#  _ __ ___   __ _ _ __   __  __
# | '_ ` _ \ / _` | '_ \  \ \/ /
# | | | | | | (_| | |_) |  >  < 
# |_| |_| |_|\__,_| .__/  /_/\_\
#                 | |           
#                 |_|           
# Map server part

#
# MAP SECTION 
#


#
# PERMISSION EVENT : loading server files
#
observe({
  if(mxReact$allowMap){
    mxReact$mapPanelMode="mapViewsExplorer"
    source("parts/server/style.R",local=TRUE)
    source("parts/server/views.R",local=TRUE)
  }
})

observe({
  if(mxReact$allowViewsCreator){
    source("parts/server/creator.R",local=TRUE)
  }
})

observe({
  if(mxReact$allowToolbox){
  source("parts/server/toolbox.R",local=TRUE)
  }
})

#
# ENABLE PANEL BUTTONs
#

observe({
  mxUiEnable(id="sectionMap",enable=mxReact$allowMap) 
})

observe({
  mxUiEnable(id="btnViewsCreator",enable=mxReact$allowViewsCreator) 
})

observe({
  mxUiEnable(id="btnViewsToolbox",enable=mxReact$allowToolbox) 
})
observe({
  mxUiEnable(id="btnStoryReader",enable=mxReact$allowStoryReader) 
})
observe({
  mxUiEnable(id="btnStoryCreator",enable=mxReact$allowStoryCreator) 
})




#
# UI ENVENT : change ui apparence
#

observeEvent(input$btnViewsExplorer,{
  mxSetMapPanelMode("mx-mode-explorer") 
  mxReact$mapPanelMode="mapViewsExplorer"
  mxUpdateText(id="titlePanelMode",text="Views explorer")
})

observeEvent(input$btnViewsConfig,{
  mxSetMapPanelMode("mx-mode-config")
  mxReact$mapPanelMode="mapViewsConfig"
  mxUpdateText(id="titlePanelMode",text="Views config")
})

observeEvent(input$btnViewsToolbox,{
  mxSetMapPanelMode("mx-mode-toolbox")
  mxReact$mapPanelMode="mapViewsToolbox"
  mxUpdateText(id="titlePanelMode",text="Views toolbox")
})
observeEvent(input$btnViewsCreator,{
  mxSetMapPanelMode("mx-mode-creator")
  mxReact$mapPanelMode="mapViewsCreator"
  mxUpdateText(id="titlePanelMode",text="Views creator")
})
observeEvent(input$btnStoryCreator,{
  mxSetMapPanelMode("mx-mode-story-creator")
  mxReact$mapPanelMode="mapStoryCreator"
  mxUpdateText(id="titlePanelMode",text="Story map creator")
})
observeEvent(input$btnStoryReader,{
  mxSetMapPanelMode("mx-mode-story-reader")
  mxReact$mapPanelMode="mapStoryReader"
  mxUpdateText(id="titlePanelMode",text="<story map>")
})
#
# Clear layer after exlorer mode enter
#
observeEvent(input$btnViewsExplorer,{
  if(mxReact$allowMap){
    mxCatch(title="Clean creator layers",{
      reactiveValuesReset(mxStyle)
      mxStyle <- reactiveValues()
      dGroup <- mxConfig$defaultGroup
      legendId <- paste0(dGroup,"_legends")
      proxyMap <- leafletProxy("mapxMap")
      proxyMap %>%
      removeControl(layerId=legendId) %>%
      clearGroup(dGroup)
  # double remove.
  mxRemoveEl(class=legendId)
        })
  }
})

#
# Clear layer after creator enter
#
observeEvent(input$btnViewsCreator,{
  if(mxReact$allowMap){

    mxStyle$group <- "G1"
    mxStyle$layer <- NULL
    mxStyle$variable <- NULL
    mxStyle$values <- NULL
      #   reactiveValuesReset(mxStyle)
      mxReact$viewsToDisplay = ""
  }
})

#
# Main map
#
output$mapxMap <- renderLeaflet({
  if(mxReact$allowMap){
    map <- leaflet()
    if(noDataCheck(mxReact$selectCountry))return()
    group = "main"
    iso3 <- mxReact$selectCountry
    if(!noDataCheck(iso3)){
      center <- mxConfig$countryCenter[[iso3]] 
      map <- mxConfig$baseLayerByCountry(iso3,group,center)
    }
    map %>% setZoomOptions(buttonOptions=list(position="topright")) 
  }
})


