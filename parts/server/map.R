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
    ## will source story creator if needed. scoping. scoping..
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
  mxUiEnable(id="btnViewsToolbox",enable=mxReact$allowToolbox) 
})
observe({
  mxUiEnable(id="btnStoryReader",enable=mxReact$allowStoryReader) 
})

observe({
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
#observeEvent(input$btnStoryCreator,{
#  mxToggleMapPanels("mx-mode-story-creator")
#  mxReact$mapPanelMode="mapStoryCreator"
#  mxUpdateText(id="titlePanelMode",text="Story map creator")
#})
observeEvent(input$btnStoryReader,{
  mxToggleMapPanels("mx-mode-story-reader")
  mxReact$mapPanelMode="mapStoryReader"
  mxUpdateText(id="titlePanelMode",text="Story map")

  # hide some buttons
#  mxUiEnable(id="btnStoryCreator",enable=mxReact$allowStoryCreator) 
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
    if(!noDataCheck(mxReact$selectCountry)){
      group = "main"
      iso3 <- mxReact$selectCountry
      if(!noDataCheck(iso3)){
        center <- mxConfig$countryCenter[[iso3]] 
        map <- mxConfig$baseLayerByCountry(iso3,group,center)
      }
      mxReact$mapInitDone<- runif(1)
      return(map)
    }
  }
})

#
# Map custom style
#

observeEvent(mxReact$mapInitDone,{
  map <- leafletProxy("mapxMap")
  map %>% setZoomOptions(buttonOptions=list(position="topright")) 
  session$sendCustomMessage(
    type="addCss",
    "mapx/leafletPatch.css"
    )
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
      "Observe for changes over time"="changes",
      "Get current attributes"="summary" 
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
  em <- input$txtDrawEmail
  sl <- input$selDrawLayer
  sa <- input$selDrawAction
  un <- mxReact$userName


  gj <- mxReact$drawActionGeoJson 
  tm <- randomName("tmp")
 
  
  dbAddGeoJSON(geojsonList=gj,tableName=tm,dbInfo=dbInfo)
  stopifnot(tm %in% mxDbListTable(dbInfo))




  q <- sprintf("SELECT * FROM %1$s INNER JOIN %2$s ON ST_Intersects(%1$s.geom, %2$s.geom);"
    ,sl
    ,tm
    )
 
  rs <- mxDbGetQuery(dbInfo,q)
  if(is.null(rs)){
    rs = data.frame(title="NO VALUE")
  }else{


    # this result will be used to compare to previous results if something changed. 

    cl <- mxDbListColumns(dbInfo,sl)


    # rm cols
    rc <- c('gid','geom','mx_date_start','mx_date_end','guidshap','guidlice','guidspat','intgeome','intshape') 

    cls <- cl[! cl %in% rc]

    rs <- rs[,names(rs) %in% cls]

  }

 
  di <- digest(rs)
  nr <- nrow(rs)
  ## send result by mail
  from <- "bot@mapx.io"
  to <- em
  subject <- paste("mapx analysis result for on layer",sl)

  msg <- sprintf(
    "Hi %1$s,
    \n here is the result for your polygon request.
    \n Number of rows = %2$s
    \n MD5 sum = %3$s",
    un,nr,di
    )


  mime_part.data.frame <- function(x, name=deparse(substitute(x)), ...) {
      f <- tempfile()
    on.exit(file.remove(f))
      write.table(x, file=f, ...)
      sendmailR:::.file_attachment(f, name=sprintf("%s.csv", name), type="text/plain")
  }


  body <- list(msg, mime_part(rs))
 

  mxDebugMsg("send the message")
  sendmail(
    from, 
    to, 
    subject, 
    body,
    control=list(smtpServer="smtp.unige.ch")
    )
  })

})


