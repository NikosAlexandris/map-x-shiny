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

  allow <- isTRUE( reactUser$allowMap )

  if( allow ){
    source("parts/server/style.R",local=TRUE)
    source("parts/server/views.R",local=TRUE)
    source("parts/server/leaflet.R",local=TRUE)
    # Inital mode
    reactUi$panelMode="mxModeExplorer"
    # temporary hardcoded tenke fungurume summary
    output$infoBoxContent <- renderUI(includeHTML("parts/ui/tenke-info.html"))
  }

  mxUiEnable(
    id="sectionMap",
    enable=allow
    )

})

# Allow map views creator
observe({

  allow <- isTRUE( reactUser$allowViewsCreator )

  if( allow ){
    source("parts/server/creator.R",local=TRUE)
  }

  mxUiEnable(
    class = "mx-allow-creator",
    enable = allow 
    )

})
# Allow data upload
observe({

  allow <- isTRUE( reactUser$allowUpload )

  if( allow ){
    source("parts/server/upload.R",local=TRUE)
  }

 mxUiEnable(
    class = "mx-allow-upload",
    enable = allow
    ) 

})


# Allow analysisOverlap
observe({

  allow <- isTRUE( reactUser$allowAnalysisOverlap )

#<<<<<<< HEAD
##
## Add sources
##

#observeEvent(input$glLoaded,{

  #proxymap <- leafletProxy("mapxMap")

  ## Country overlay source
  #tilesCountry <- glMakeUrl(
    #protocol = mxConfig$protocolVtPublic,
    #host = mxConfig$hostVt,
    #port= mxConfig$portVtPublic,
    #table="mx_country_un",
    #fieldVariables="iso3code",
    #fieldGeom="geom"
    #)

 
  #srcSatellite = list(
    #url = "mapbox://mapbox.satellite",
    #type = "raster",
    #tileSize = 256 
    #)

  #srcSatelliteHere = list(
    #tiles = c(
    #"https://1.aerial.maps.cit.api.here.com/maptile/2.1/basetile/newest/satellite.day/{z}/{x}/{y}/512/jpg?app_id=8O8WmE7U46S3sj93t9TN&app_code=k8YdYxvaliuJc1nz99d-ZA&ppi=72",
    #"https://2.aerial.maps.cit.api.here.com/maptile/2.1/basetile/newest/satellite.day/{z}/{x}/{y}/512/jpg?app_id=8O8WmE7U46S3sj93t9TN&app_code=k8YdYxvaliuJc1nz99d-ZA&ppi=72"),
    #type="raster",
    #tileSize = 512
    #)

#=======
  if( allow ){
    source("parts/server/analysisOverlap.R",local=TRUE)
  }
#>>>>>>> user_management

 mxUiEnable(
    class = "mx-allow-overlap",
    enable = allow
    )

})

# Allow polygon of interest
observe({

  allow <- isTRUE( reactUser$allowPolygonOfInterest )

  if( allow ){
    source("parts/server/polygonOfInterest.R",local=TRUE)
  }
  
 mxUiEnable(
    class = "mx-allow-polygon-of-interest",
    enable = allow
    )

})

# Allow toolbox 
observe({

  allow <- isTRUE( reactUser$allowToolbox )

  mxUiEnable(
    id="btnViewsToolbox",
    enable = allow
    ) 

})



# Allow story map 
observe({

  allow <- isTRUE( reactUser$allowStoryReader )

  if( allow ){
    source("parts/server/storyReader.R",local=TRUE)
  }

  mxUiEnable(
    id = "btnModeStoryReader",
    enable = allow
    ) 



})

# Allow story map creator
observe({

  allow <- isTRUE( reactUser$allowStoryCreator )

  if( allow ){
     source("parts/server/storyCreator.R",local=TRUE)
  }

  mxUiEnable(
    class = "mx-allow-story-creator",
    enable = allow
    )

})

# Show story custom buttons
observe({

  enable <- isTRUE(reactUser$allowStoryCreator) &&
    isTRUE(reactUser$allowEditCurrentStory) &&
    isTRUE(reactUi$panelMode == "mxModeStoryMap")

  mxUiEnable(
    class="mx-allow-story-edit",
    enable=enable
    )

})




# update panel mode 
observeEvent(input$mxPanelMode,{
  currentMode <- input$mxPanelMode$id

  reactUi$panelMode <- currentMode

  mxDebugMsg(sprintf("Current panel mode= %s",currentMode))

  isStoryMode <- isTRUE(currentMode == "mxModeStoryMap")

  mxUiEnable(
    class="mx-mode-story-reader",
    enable=isStoryMode
    )

})



