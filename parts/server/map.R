#
# MAP SECTION 
#

# Default base layer for testing
mxConfig$baseLayerByCountry = function(iso3="AFG",group="main",center=c(lng=0,lat=0,zoom=5)){
  switch(iso3,
    "COD"={
      leaflet() %>%
      clearGroup(group) %>%
      addTiles(
        paste0(
          "http://",
          mxConfig$hostVt,":",
          mxConfig$portVtPublic,
          "/services/tiles/cod_base_layer_0_6/{z}/{x}/{y}.png"
          ),
        group=group,
        options=list(
          "zIndex"=-5,
          "minZoom"=0,
          "maxZoom"=6)
        ) %>%  
      addTiles(
        paste0(
          "http://",
          mxConfig$hostVt,":",
          mxConfig$portVtPublic,
          "/services/tiles/cod_base_layer_7_10/{z}/{x}/{y}.png"
          ),
        group=group,
        options=list(
          "zIndex"=-5,
          "minZoom"=7,
          "maxZoom"=10)
        ) %>%
      setView(center$lng,center$lat,center$zoom)
    },
    "AFG"={
      leaflet() %>%
      clearGroup(group) %>%
      addTiles(
        paste0(
          "http://",
          mxConfig$hostVt,":",
          mxConfig$portVtPublic,
          "/services/tiles/afg_base_layer/{z}/{x}/{y}.png"
          ),
        group=group,
        options=list(
          "zIndex"=-5
          )
        )%>% setView(center$lng,center$lat,center$zoom)
    } 
    )
}


# Default label layer for testing
mxConfig$labelLayerByCountry=function(iso3,group,proxyMap){
  switch(iso3,
    "COD"={
      proxyMap %>%
      clearGroup(group) %>%
      addTiles(
        paste0(
          "http://",
          mxConfig$hostVt,":",
          mxConfig$portVtPublic,
          "/services/tiles/cod_labels_0_6/{z}/{x}/{y}.png"
          ),
        group=group,
        options=list(
          "zIndex"=30,
          "minZoom"=0,
          "maxZoom"=6)
        ) %>%  addTiles(
        paste0(
          "http://",
          mxConfig$hostVt,":",
          mxConfig$portVtPublic,
          "/services/tiles/cod_labels_7_10/{z}/{x}/{y}.png"
          ),
        group=group,
        options=list(
          "zIndex"=30,
          "minZoom"=7,
          "maxZoom"=10)
        )
    },
    "AFG"={
      proxyMap %>%
      clearGroup(group) %>%
      addTiles(
        paste0(
          "http://",
          mxConfig$hostVt,":",
          mxConfig$portVtPublic,
          "/services/tiles/afg_labels/{z}/{x}/{y}.png"
          ),
        group=group,
        options=list(
          zIndex=30
          )
        )
    }
    )
}





observe({
  # Enable map ui if allowMap is true
  mxUiEnable(id="sectionMap",enable=mxReact$allowMap) 
})

observe({
  # Enable ui if allow map is true
  mxUiEnable(id="btnViewsCreator",enable=mxReact$allowViewsCreator) 
})

observe({
  if(mxReact$allowMap){
    source("parts/server/style.R",local=TRUE)
    source('parts/server/panelMode.R',local=TRUE)
    source("parts/server/views.R",local=TRUE)

    # Clear layer after exlorer mode enter
    observeEvent(input$btnViewsExplorer,{
      mxCatch(title="Clean creator layers",{
        mxStyle <- reactiveValues()
        dGroup <- mxConfig$defaultGroup
        legendId <- paste0(dGroup,"_legends")
        proxyMap <- leafletProxy("mapxMap")
        proxyMap %>%
        clearGroup(dGroup) %>% 
        removeControl(legendId) 
          })
        })

    # Clear layer after creator enter
    observeEvent(input$btnViewsCreator,{
      source("parts/server/creator.R",local=TRUE)
      mxCatch(title="Clean explorer layers",{
        mxStyle <- reactiveValues()
        mxReact$viewsToDisplay = ""
          })
        })

    # Main map
    output$mapxMap <- renderLeaflet({
      if(noDataCheck(mxReact$selectCountry))return()
      group = "main"
      iso3 <- mxReact$selectCountry
      if(!noDataCheck(iso3)){
        center <- mxConfig$countryCenter[[iso3]] 
        mxConfig$baseLayerByCountry(iso3,group,center)
      }
    })
  }
})
