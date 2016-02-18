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
  }
})

# Allow map views creator
observe({
  if(mxReact$allowViewsCreator){
    source("parts/server/creator.R",local=TRUE)
  }
})
# Allow story map 
observe({
  if(mxReact$allowStoryReader){
    source("parts/server/storyReader.R",local=TRUE)
    #NOTE: we need to source storyCreator inside story reader. 
    #TODO: give the sesstion environment instead of local=TRUE ?
  }
})


# Allow toolbox / analysis
observe({
  if(mxReact$allowToolbox){
    source("parts/server/toolbox.R",local=TRUE)
  }
})

#
#observeEvent(input$mapxMap_center,{
#  center <- input$mapxMap_center
#  
# res <-  dbGetValByCoord(dbInfo,table="mx_country_un",column="iso3code",lat=center$lat,lng=center$lng,distKm=20)
#iso3 <- res$result[["iso3code"]]
#
#if(!noDataCheck(iso3)){
# updateSelectInput(session,"selectCountry",selected=iso3)
#}
#})
#


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
  mxUpdateText(id="titlePanelMode",text="Story map")
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
# Map set center and overlay
#


#' Create url for pgrestapi source
#' @return url 
glMakeUrl <- function(
  host,
  port,
  table,
  fieldVariables,
  fieldGeom
  ){
 # layer <- paste0(table,"_",fieldGeom) 
  query <- sprintf("?fields=%s",paste(fieldVariables,collapse=",")) 
  url <- sprintf("http://%s:%s/services/postgis/%s/%s/vector-tiles/{z}/{x}/{y}.pbf%s",
    host,
    port,
    table,
    fieldGeom,
    query)

 return(c(url,url))
}

#
# Add sources
#

observeEvent(input$glLoaded,{

  proxymap <- leafletProxy("mapxMap")

  # Country overlay source
  tilesCountry <- glMakeUrl("localhost","8080","mx_country_un","iso3code","geom")

  proxymap  %>%
  glAddSource(
    idGl = "basemap",
    idSource = "mapboxsat",
    url = "mapbox://mapbox.satellite",
    type = "raster",
    tileSize = 256
    ) %>%  
  glAddSource(
    idGl = "basemap",
    idSource = "country",
    tiles = tilesCountry,
    type = "vector"
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
    `source-layer` = "mx_country_un_geom",
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
      "Get current attributes"="summary",
      "Observe for changes over time"="changeOverTime",
      "Observe location change"="changeOverLocation"
      )

    ui <- tagList(
      selectInput("selDrawLayer","Select a layer",choices=layers),
      selectInput("selDrawAction","Select an action",choices=actions),
      textInput("txtDrawEmail","Enter your email",value=mxReact$userEmail),
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
  validEmail <- isTRUE(grep("(^[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\\.[a-zA-Z0-9-.]+$)",em,perl=T) > 0)

  # layer
  validLayer <- isTRUE(sl != mxConfig$noData )


  # action
  validAction <- isTRUE(sa != mxConfig$noData)

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
  # user name
  un <- mxReact$userName
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
  tp <- randomName("mx_poi_")
  # table for inner join (result)
  tr <- randomName("tmp__poi_res")
  # columns to import
  lc <- mxDbListColumns( dbInfo, sl )
  # add geojson to tp
  dbAddGeoJSON(
    geojsonList=gj,
    tableName=tp,
    dbInfo=dbInfo
    )
  # test if tp is available
  stopifnot(tp %in% mxDbListTable(dbInfo))
  # do an overlap analysis
  mxAnalysisOverlaps(
    dbInfo,
    sl,
    tp,
    tr,
    varToKeep = lc
    )
  # get number of row returner
  cr <- mxDbGetQuery(dbInfo,sprintf("SELECT COUNT(gid) FROM %s",tr))$count

if(cr>0){
qr <- sprintf("SELECT * FROM %s",tr)
tmp <- dbGetGeoJSON(dbInfo,query=qr)
de <- sprintf("Polygon of interest %1$s based on %2$s",tp,sl)
if( file.exists(tmp)){
  # creating a gist ! alternative : create a geojson in www/data/poi
  ur <- system(sprintf("gist -p %1$s -d '%2$s'",tmp,de),intern=T) 
  #poiPath<- sprintf("www/data/poi/%1$s.geojson",tp)
  #ur <- sprintf("https://github.com/fxi/map-x-shiny/blob/master/%s",poiPath)
  #file.rename(tmp,poiPath)
  #browser()
  #system(sprintf("git add %1$s",poiPath))
  #system("git commit -m 'update poi'")
  #system("git push")
}
}

# output message

if( cr > 0 && length(ur) > 0){
  di <- digest(file=tmp)
  ms <- sprintf(
    "Dear %1$s,
    \n Here is the result for your polygon request with id \"%2$s\"
    \n link to data = %3$s
    \n Number of rows = %4$s
    \n MD5 sum = %5$s.
    Have a nice day !",
    un,tp,ur,cr,di
    )
}else{
ms <- sprintf(
  "Dear %1$s,
  There is no data for the polygon of interest requested.
  The id of this request is '%2$s'
  Have a nice day !",
  un,tp
  )
}

mxDbGetQuery(dbInfo,sprintf("DROP TABLE IF EXISTS %s",tr))


sendEmail <- sprintf("echo '%1$s' | mail -s 'map-x : polygon of interest %2$s' -a 'From: %3$s' %4$s",
  ms,
  tp,
  am,
  em
  )


if( mxConfig$hostname != "map-x-full" ){
  if(!exists("remoteInfo"))stop("No remoteInfo found in /settings/settings.R")
  r <- remoteInfo  
  remoteCmd(host="map-x-full",cmd=sendEmail)
}else{
  system(sendEmail)
}

output$panelAlert <- renderUI( mxPanelAlert(
    title="message",
    subtitle="Email sent !",
    message=ms
    )
  )

 
  })
      })




