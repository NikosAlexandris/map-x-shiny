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


# use memoise to cache some function
addPaletteFun_cache <- memoise(addPaletteFun)
mxMakeViews_cache <- memoise(mxMakeViews)

#
# PERMISSION EVENT : loading server files
#
observe({
  if(reactUser$allowMap){
    source("parts/server/style.R",local=TRUE)
    source("parts/server/views.R",local=TRUE)
    source("parts/server/leaflet.R",local=TRUE)
    # Inital mode
    reactUi$panelMode="mapViewsExplorer"

    output$infoBoxContent <- renderUI(includeHTML("parts/ui/tenke-info.html"))
  }
})

# update panel mode 
observeEvent(input$mxPanelMode,{
  reactUi$panelMode<-input$mxPanelMode$id
})


# Allow map views creator
observe({
  if(reactUser$allowViewsCreator){
    source("parts/server/creator.R",local=TRUE)
  }
})

# Allow data upload
observe({
  if(reactUser$allowUpload){
    source("parts/server/upload.R",local=TRUE)
  }
})
# Allow story map 
observe({
  if(reactUser$allowStoryReader){
    source("parts/server/storyReader.R",local=TRUE)
  }
})


# Allow toolbox / analysis
observe({
  if(reactUser$allowAnalysisOverlap){
    source("parts/server/analysisOverlap.R",local=TRUE)
  }
})

observe({
  if(reactUser$allowPolygonOfInterest){
    source("parts/server/polygonOfInterest.R",local=TRUE)
  }
})


observe({
mxDebugMsg(sprintf("Current panel mode= %s",input$mxPanelMode))
})


#
# UI by user privilege
#
observe({
  mxUiEnable(id="sectionMap",enable=reactUser$allowMap) 
})

observe({
  mxUiEnable(
    class="mx-allow-creator",
    enable=isTRUE( reactUser$allowViewsCreator) 
    )
})

observe({
  mxUiEnable(
    class="mx-allow-polygon-of-interest",
    enable=isTRUE( reactUser$allowPolygonOfInterest) 
    )
})

observe({
  mxUiEnable(
    class="mx-allow-upload",
    enable = reactUser$allowUpload
    ) 
})

observe({
  mxUiEnable(
    id="btnViewsToolbox",
    enable = reactUser$allowToolbox
    ) 
})

observe({
  mxUiEnable(
    id="btnModeStoryReader",
    enable=reactUser$allowStoryReader
    ) 
})

observe({
  mxUiEnable(
    class="mx-allow-story-creator",
    enable=reactUser$allowStoryCreator
    )
})

observe({

  enable <- isTRUE(reactUser$allowStoryCreator) &&
    isTRUE(reactUser$allowEditCurrentStory) &&
    isTRUE(reactUi$panelMode == "mapStoryReader")

  mxUiEnable(
    class="mx-allow-story-edit",
    enable=enable
    )
})


