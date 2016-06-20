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
    # Inital mode
    reactUi$panelMode="mapViewsExplorer"

    output$infoBoxContent <- renderUI(includeHTML("parts/ui/tenke-info.html"))
  }
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
  if(reactUser$allowToolbox){
    source("parts/server/toolbox.R",local=TRUE)
  }
})


#
# UI by user privilege
#
observe({
  mxUiEnable(id="sectionMap",enable=reactUser$allowMap) 
})

observe({
  mxUiEnable(id="btnViewsCreator",enable=reactUser$allowViewsCreator) 
})
observe({
  mxUiEnable(id="tabDataUpload",enable=reactUser$allowUpload) 
})
observe({
  mxUiEnable(id="btnViewsToolbox",enable=reactUser$allowToolbox) 
})
observe({
  mxUiEnable(id="btnStoryReader",enable=reactUser$allowStoryReader) 
  
})
observe({
  mxUiEnable(id="btnStoryCreator",enable=reactUser$allowStoryCreator)
  mxUiEnable(class="mx-allow-story-edit",enable=reactUser$allowStoryCreator)
})

#
# UI by user event
#

observeEvent(input$btnViewsExplorer,{
  mxToggleMapPanels("mx-mode-explorer") 
  reactUi$panelMode="mapViewsExplorer"
  mxUpdateText(id="titlePanelMode",text="Views explorer")
})

observeEvent(input$btnViewsConfig,{
  mxToggleMapPanels("mx-mode-config")
  reactUi$panelMode="mapViewsConfig"
  mxUpdateText(id="titlePanelMode",text="Views config")
})

observeEvent(input$btnViewsToolbox,{
  mxToggleMapPanels("mx-mode-toolbox")
  reactUi$panelMode="mapViewsToolbox"
  mxUpdateText(id="titlePanelMode",text="Views toolbox")
})
observeEvent(input$btnViewsCreator,{
  mxToggleMapPanels("mx-mode-creator")
  reactUi$panelMode="mapViewsCreator"
  mxUpdateText(id="titlePanelMode",text="Views creator")
})

observeEvent(input$btnStoryReader,{
  mxToggleMapPanels("mx-mode-story-reader")
  reactUi$panelMode="mapStoryReader"
  mxUpdateText(id="titlePanelMode",text="Story maps")
})


observeEvent(reactUi$panelMode,{
  if(reactUi$panelMode %in% c("mapViewsCreator","mapViewsExplorer")){
    reactMap$viewsDataToDisplay = ""
    mxStyleReset(mxStyle)
    if( reactUi$panelMode == "mapViewsExplorer"){
      dGroup <- mxConfig$defaultGroup
      legendId <- paste0(dGroup,"_legends")
      proxyMap <- leafletProxy("mapxMap")
      proxyMap %>%
      removeControl(layerId=legendId) %>%
      clearGroup(dGroup)  
    }
  }
})




#
# Map init
#

observeEvent(reactUser$allowMap,{
  output$mapxMap <- renderLeaflet( leaflet() )
  reactMap$mapInitDone <- runif(1)
})




observeEvent(reactUser$allowMap,{

  if(reactUser$allowMap){

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

  srcSatelliteHere = list(
    tiles = c(
      "https://1.aerial.maps.cit.api.here.com/maptile/2.1/basetile/newest/satellite.day/{z}/{x}/{y}/512/jpg?app_id=kaq3He8C5WiDCB2yadWE&app_code=vvvkBHJXgetE5n9fRQxrOA&ppi=72",
      "https://2.aerial.maps.cit.api.here.com/maptile/2.1/basetile/newest/satellite.day/{z}/{x}/{y}/512/jpg?app_id=kaq3He8C5WiDCB2yadWE&app_code=vvvkBHJXgetE5n9fRQxrOA&ppi=72"),
    type="raster",
    tileSize = 512
    )


  srcCountry = list(
    url = "mapbox://unepgrid.6idtkx33",
    type = "vector" 
    )
  
 
    #
    # Render leaflet object
    #
  output$mapxMap <- renderLeaflet({
    map <- leaflet()  %>% 
      setZoomOptions(buttonOptions=list(position="topright")) %>%
      glInit(
        idGl = "basemap",
        style = mxConfig$mapboxStyle,
        token = mxConfig$mapboxToken) %>%
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
        ) 
        # patch css after map initialisation. 
        #
        session$sendCustomMessage(
          type="addCss",
          "src/mapx/css/leafletPatch.css"
          )
      reactMap$mapInitDone <- runif(1)
        #
        # Render map object
        #
        return(map)
    })
  }
})


#
# Update center
#


observe({

  iso3 <- reactProject$name
  cntOk <- isTRUE(!noDataCheck( iso3 ))
  initOk <-isTRUE(!noDataCheck( reactMap$mapInitDone ))
  

  if( cntOk && initOk ){

    #
    # Get country center
    #

    center <- mxConfig$countryCenter[[ iso3 ]]

    okCountryCenter <- isTRUE( 
      ! is.null(center) &&
        all( c( "lat", "lng", "zoom" ) %in% names( center ))
      )

    stopifnot(okCountryCenter)

    #
    # Set view on country center
    #

    leafletProxy("mapxMap") %>%
      setView(
        lng=center$lng,
        lat=center$lat,
        zoom=center$zoom)

    #
    # Update map map init reactive value
    #

  }

})







#
# Add sources
#

#observeEvent(input$glLoaded,{

  #mxDebugMsg("gl loaded : add sources")

  #proxymap <- leafletProxy("mapxMap")

    #})


observeEvent(input$glLoaded,{
  mxDebugMsg("gl loaded event")

  browser()
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



#
# update country extent
#




observe({

  layId <- "countryOverlay"
  iso3 <- reactProject$name
  cntOk <- isTRUE(!noDataCheck( iso3 ))
  initOk <-isTRUE(!noDataCheck( reactMap$mapInitDone ))
  glOk <- isTRUE( input$glLoadedLayer == layId )

  if( initOk && glOk && cntOk && glOk ){

    # if the country code match, don't paint it.
    filt <- c("!in", 'iso3code', iso3 )
    proxyMap <- leafletProxy("mapxMap")
    proxyMap %>%
    glSetFilter(
      idGl="basemap",
      idLayer=layId,
      filter=filt
      )


  }
})





#
# Leaflet draw
#

observeEvent(input$btnDraw,{
  pMap <- leafletProxy("mapxMap")
  pMap %>% addDraw(options=list(position="topright"))
})



observeEvent(input$leafletDrawGeoJson,{

  mxCatch(title="Polygon of interest",{

    v = reactMap$viewsData
    layers = lapply(v,function(x){x$layer})
    names(layers) = lapply(v,function(x){x$title})
    layers <- c(mxConfig$noData,unlist(layers))
    actions <- c(
      mxConfig$noData,
      "Get current attributes"="summary"
      )

    ui <- tagList(
      selectInput("selDrawLayer","Select a layer",choices=layers),
      selectInput("selDrawAction","Select an action",choices=actions),
      textInput("txtDrawEmail","Enter your email",value=reactUser$data$email),
      div(id="txtValidationDraw")
      )

    bnts <- tagList(
      actionButton("btnDrawActionConfirm","confirm",class="btn-modal")
      )

    panModal <- mxPanel(
      id="panDrawModal",
      title="Polygon of interest",
      subtitle="Action handler",
      html=ui,
      listActionButton=bnts,
      addCancelButton=TRUE
      )

    mxUpdateText(id="panelAlert",ui=panModal)
    reactMap$drawActionGeoJson <- input$leafletDrawGeoJson
        })
})



#
# Validation
#



observe({

  # intuts
  em <- input$txtDrawEmail
  sl <- input$selDrawLayer
  sa <- input$selDrawAction
  un <- reactUser$name


  # errory message
  err = character(0)

  # email
  validEmail <- mxEmailIsValid(em)

  # layer
  validLayer <- !noDataCheck(sl) 


  # action
  validAction <- !noDataCheck(sa) 

  # set messages
  if(!validEmail) err <- c(err,"Please enter a valid email")
  if(!validLayer) err <- c(err,"Plase select a layer")
  if(!validAction) err <- c(err,"Please select an action (only 'Get current attributes works in the prototype')")

  # validation action
  if(length(err)>0){
    err<-tags$ul(
      HTML(paste("<li>",icon('exclamation-triangle'),err,"</li>",collapse=""))
      )
    disBtn=TRUE
  }else{
    err=""
    disBtn=FALSE
  }

  # update issues text
  mxUpdateText(id="txtValidationDraw",text=err)

  # change button state
  mxActionButtonState("btnDrawActionConfirm",disable=disBtn) 

}
  )


 
observeEvent(input$btnDrawActionConfirm,{
  mxCatch(title="Polygon of interest : processing",{

 # inputs
  # entered email
  em <- input$txtDrawEmail
  # automatic email adress
  am <- mxConfig$mapxBotEmail
  # seleced layer
  sl <- input$selDrawLayer
  # selected action
  sa <- input$selDrawAction
  # out message
  ms <- character(0)
  # url of the result
  ur <- character(0)
  # digest code (md5 sum of the file) 
  di <- character(0)
  # description of the poi
  de <- character(0)
  # get actual geojson from client
  gj <- reactMap$drawActionGeoJson 
  # table for polygon
  tp <- tolower(randomString("mx_poi",splitSep="_",splitIn=5,n="30"))
  # table for inner join (result)
  tr <- tolower(randomString("mx_poi",splitSep="_",splitIn=5,n="30"))
  # columns to import
  lc <- mxDbGetColumnsNames( sl )
  # add geojson to tp
  mxDbAddGeoJSON(
    geojsonList = gj,
    tableName = tp
    )
  # test if tp is available
  stopifnot(mxDbExistsTable(tp))
  # do an overlap analysis

  mxAnalysisOverlaps(
    sl,
    tp,
    tr,
    varToKeep = lc
    )
  # get number of row returner
  cr <- mxDbGetQuery(sprintf("SELECT COUNT(gid) as count FROM %s",tr))$count

  if(noDataCheck(cr)) stop("Empty result from layer")

  if(cr>0){
    qr <- sprintf("SELECT * FROM %s",tr)
    tmp <- mxDbGetGeoJSON(query=qr)
    de <- sprintf("Polygon of interest %1$s based on %2$s",tp,sl)
    if( file.exists(tmp)){
      # creating a gist ! alternative : create a geojson in www/data/poi
      ur <- system(sprintf("gist -p %1$s -d '%2$s'",tmp,de),intern=T) 
      #poiPath<- sprintf("www/data/poi/%1$s.geojson",tp)
      #ur <- sprintf("https://github.com/fxi/map-x-shiny/blob/master/%s",poiPath)
      #file.rename(tmp,poiPath)
      #system(sprintf("git add %1$s",poiPath))
      #system("git commit -m 'update poi'")
      #system("git push")
    }
  }

# output message

  if( cr > 0 && length(ur) > 0){
    di <- digest(file=tmp)
    ms <- sprintf(
      "Dear map-x user,
      \n Here is the result for your polygon request with id \"%1$s\"
      \n link to data = %2$s
      \n Number of rows = %3$s
      \n MD5 sum = %4$s.
      Have a nice day !",
      tp,ur,cr,di
      )
  }else{
    ms <- sprintf(
      "Dear map-x-user,
      There is no data for the polygon of interest requested.
      The id of this request is '%1$s'
      Have a nice day !",
      tp
      )
  }

mxDbGetQuery(sprintf("DROP TABLE IF EXISTS %s",tr))

sub <- sprintf("map-x : polygon of interest %1$s",tp)

mxSendMail(
  from=mxConfig$mapxBotEmail,
  to=em,
  body=ms,
  subject=sub,
  wait=FALSE
  )


output$panelAlert <- renderUI( mxPanelAlert(
    title="message",
    subtitle="Email sent !",
    message=ms
    )
  )

 
  })
      })




