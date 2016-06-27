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
  if(mxReact$allowMap){
    source("parts/server/style.R",local=TRUE)
    source("parts/server/views.R",local=TRUE)
    # Inital mode
    mxReact$mapPanelMode="mapViewsExplorer"

    output$infoBoxContent <- renderUI(includeHTML("parts/ui/tenke-info.html"))
  }
})

# Allow map views creator
observe({
  if(mxReact$allowViewsCreator){
    source("parts/server/creator.R",local=TRUE)
  }
})

# Allow data upload
observe({
  if(mxReact$allowDataUpload){
    source("parts/server/upload.R",local=TRUE)
  }
})
# Allow story map 
observe({
  if(mxReact$allowStoryReader){
    source("parts/server/storyReader.R",local=TRUE)
  }
})


# Allow toolbox / analysis
observe({
  if(mxReact$allowToolbox){
    source("parts/server/toolbox.R",local=TRUE)
  }
})


#
# UI by user privilege
#
observe({
  mxUiEnable(id="sectionMap",enable=mxReact$allowMap) 
})

observe({
  mxUiEnable(id="btnViewsCreator",enable=mxReact$allowViewsCreator) 
})
observe({
  mxUiEnable(id="tabDataUpload",enable=mxReact$allowDataUpload) 
})
observe({
  mxUiEnable(id="btnViewsToolbox",enable=mxReact$allowToolbox) 
})
observe({
  mxUiEnable(id="btnStoryReader",enable=mxReact$allowStoryReader) 
  
})
observe({
  mxUiEnable(id="btnStoryCreator",enable=mxReact$allowStoryCreator)
  mxUiEnable(class="mx-allow-story-edit",enable=mxReact$allowStoryCreator)
})

#
# UI by user event
#

observeEvent(input$btnViewsExplorer,{
  mxToggleMapPanels("mx-mode-explorer") 
  mxReact$mapPanelMode="mapViewsExplorer"
  mxUpdateText(id="titlePanelMode",text="Views explorer")
})

observeEvent(input$btnViewsConfig,{
  mxToggleMapPanels("mx-mode-config")
  mxReact$mapPanelMode="mapViewsConfig"
  mxUpdateText(id="titlePanelMode",text="Views config")
})

observeEvent(input$btnViewsToolbox,{
  mxToggleMapPanels("mx-mode-toolbox")
  mxReact$mapPanelMode="mapViewsToolbox"
  mxUpdateText(id="titlePanelMode",text="Views toolbox")
})
observeEvent(input$btnViewsCreator,{
  mxToggleMapPanels("mx-mode-creator")
  mxReact$mapPanelMode="mapViewsCreator"
  mxUpdateText(id="titlePanelMode",text="Views creator")
})

observeEvent(input$btnStoryReader,{
  mxToggleMapPanels("mx-mode-story-reader")
  mxReact$mapPanelMode="mapStoryReader"
  mxUpdateText(id="titlePanelMode",text="Story maps")
})


observeEvent(mxReact$mapPanelMode,{
  if(mxReact$mapPanelMode %in% c("mapViewsCreator","mapViewsExplorer")){
    mxReact$viewsToDisplay = ""
    mxStyleReset(mxStyle)
    if( mxReact$mapPanelMode == "mapViewsExplorer"){
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
# Main map
#


output$mapxMap <- renderLeaflet({
  if(mxReact$allowMap){    
    map <- leaflet() 
    mxReact$mapInitDone<- runif(1)
    return(map)
  }
})



#
# Map custom style
#

observeEvent(mxReact$mapInitDone,{

  map <- leafletProxy("mapxMap")
  map %>% 
glInit(
  idGl="basemap",
  style=mxConfig$mapboxStyle,
  token=mxConfig$mapboxToken)%>%
  setZoomOptions(buttonOptions=list(position="topright")) 
  session$sendCustomMessage(
    type="addCss",
    "src/mapx/css/leafletPatch.css"
    )
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
    ) 

    })


observeEvent(input$glLoaded,{
  mxDebugMsg("gl loaded")

  initOk <- mxReact$mapInitDone > 0
  
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
  iso3 <- mxReact$selectCountry
  cnt <- !noDataCheck( iso3 )
  ini <- !noDataCheck( mxReact$mapInitDone )
  lay <- isTRUE( input$glLoadedLayer == layId )

  if( cnt && ini && lay ){

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

    v = mxReact$views
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
      textInput("txtDrawEmail","Enter your email",value=mxReact$userInfo$email),
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
    mxReact$drawActionGeoJson <- input$leafletDrawGeoJson
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
  un <- mxReact$userName


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
  gj <- mxReact$drawActionGeoJson 
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




