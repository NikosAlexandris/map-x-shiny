
#
# Main map
#


output$mapxMap <- renderLeaflet({
  if(reactUser$allowMap){    
    map <- leaflet()
    
  
    reactMap$mapInitDone<- runif(1)
    return(map)
  }
})

#
# Report error from js
#
observeEvent(input$leafletVtError,{
  mxCatch(title="Leaflet Vector Tile Issue",{
    err <- input$leafletVtError 
    if( !noDataCheck(err)) stop(err)
})
})



#<span class="leaflet-control leaflet-bar" title="Click on feature to display attributes">
  #<input class="toolCheck" type="checkbox" name="checkAttributes" value="valuable" id="checkAttributes" />
  #<label for="checkAttributes"><i class="fa fa-question "></i></label>
#</span>



#
# Map custom style
#

observeEvent(reactMap$mapInitDone,{
  mxCatch(title="After init done",{
  map <- leafletProxy("mapxMap")
  map %>% 
glInit(
  idGl="basemap",
  style = mxConfig$mapboxStyle,
  token = mxConfig$mapboxToken
  ) %>%
  setZoomOptions(
    buttonOptions = list(
      position = "topright"
      )
    ) 
  
  session$sendCustomMessage(
    type="addCss",
    "src/mapx/css/leafletPatch.css"
    )
})
})


#
# Handle leaflet draw tool
#

observeEvent(input$mxPoiDrawShow,{

  display <- input$mxPoiDrawShow
map <- leafletProxy("mapxMap")
  map %>% 
  setDraw(options=list(position="topright"),display=display)
})


#
# Add sources
#

observeEvent(input$glLoaded,{

  proxymap <- leafletProxy("mapxMap")

  # Country overlay source
  tilesCountry <- glMakeUrl(
    protocol = mxConfig$protocolVtPublic,
    host = mxConfig$hostVt,
    port= mxConfig$portVtPublic,
    table="mx_country_un",
    fieldVariables="iso3code",
    fieldGeom="geom"
    )

 
  srcSatellite = list(
    url = "mapbox://mapbox.satellite",
    type = "raster",
    tileSize = 256 
    )

  srcSatelliteLive = list(
    url = "mapbox://mapbox.landsat-live",
    type = "raster",
    tileSize = 256 
    )

 srcSatelliteHere = list(
    tiles = c(
    "https://1.aerial.maps.cit.api.here.com/maptile/2.1/basetile/newest/satellite.day/{z}/{x}/{y}/512/jpg?app_id=8O8WmE7U46S3sj93t9TN&app_code=k8YdYxvaliuJc1nz99d-ZA&ppi=72",
    "https://2.aerial.maps.cit.api.here.com/maptile/2.1/basetile/newest/satellite.day/{z}/{x}/{y}/512/jpg?app_id=8O8WmE7U46S3sj93t9TN&app_code=k8YdYxvaliuJc1nz99d-ZA&ppi=72"),
    type="raster",
    tileSize = 512
    )


  srcCountry = list(
    url = "mapbox://unepgrid.6idtkx33",
    type = "vector" 
    )
  
  proxymap  %>%
  glAddSource(
    idGl = "basemap",
    idSource = "mapboxsat",
    style = srcSatellite
    ) %>%  
  glAddSource(
    idGl = "basemap",
    idSource = "country",
    style = srcCountry
    ) %>% 
  glAddSource(
    idGl = "basemap",
    idSource = "heresat",
    style = srcSatelliteHere
    ) %>% 
  glAddSource(
    idGl = "basemap",
    idSource = "mapboxsatlive",
    style = srcSatelliteLive
    ) 

    })


observeEvent(input$glLoaded,{
  mxDebugMsg("gl loaded")

  initOk <- reactMap$mapInitDone > 0
  
  isolate({

  if(
    isTRUE( initOk )
    ){




  countryStyle  = list(
    `id` = "countryOverlay",
    `source` = "country",
    #`source-layer` = "mx_country_un_geom",
    `source-layer` = "mx_country_un_iso3code",
    `type`="fill",
    `paint`= list(
      `fill-color`="rgba(47,47,47,0.6)",
      `fill-outline-color`="rgba(47,47,47,0.2)"
      )
    )


    proxymap <- leafletProxy("mapxMap")

    proxymap %>%
       glAddLayer(
      idGl = "basemap",
      idBelowTo = NULL,
      style= countryStyle
      )
  }
  })
})



buttonAttributes <- tags$div(
  title="Toggle vector attributes information mode",
  tags$input(
    class="leaflet-checkbox",
    type="checkbox",
    name="checkAttributes",
    id="checkAttributes",
    value="attributes"
    ),
  tags$label(
    class="leaflet-button-mapx",
    `for`="checkAttributes",
    tags$i(class="mx mx-cursor-question")
    #icon("info-circle")
  )
  )
buttonSatellite <- tags$div(
  title="Toggle satellite imagery",
  tags$input(
    type="checkbox",
    class="leaflet-checkbox",
    name="checkSatellite",
    id="checkSatellite",
    value="attributes"
    ),
  tags$label(
    class="leaflet-button-mapx",
    `for`="checkSatellite",
    tags$i(class="mx mx-satellite")
  )
  )
#
# update country extent
#

observe({

  layId <- "countryOverlay"
  iso3 <- reactProject$name
  cnt <- !noDataCheck( iso3 )
  ini <- !noDataCheck( reactMap$mapInitDone )
  lay <- isTRUE( layId %in% input$glLoadedLayers )
  done <- !noDataCheck( isolate( reactMap$mapCountryOverlayDone ) )

  if( cnt && ini && lay && !done ){
    reactMap$mapCountryOverlayDone <- runif(1)
    center <- mxConfig$countryCenter[[ iso3 ]] 

    # if the country code match, don't paint it.
    filt <- c("!in", 'iso3code', iso3 )

    proxyMap <- leafletProxy("mapxMap")

    proxyMap %>%
    setView(center$lng,center$lat,center$zoom) %>%
    glSetFilter(
      idGl="basemap",
      idLayer=layId,
      filter=filt
      ) %>%
  addControl(
    buttonAttributes,
    className = "leaflet-control leaflet-bar",
    position = "topright"
    ) %>%
  addControl(
    buttonSatellite,
    className = "leaflet-control leaflet-bar",
    position = "topright"
    )
  }

})

