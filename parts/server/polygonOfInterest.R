

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
      addCancelButton=TRUE,
      defaultTextHeight=250
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



