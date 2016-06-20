#                             
#  _ __ ___   __ _ _ __   __  __
# | '_ ` _ \ / _` | '_ \  \ \/ /
# | | | | | | (_| | |_) |  >  < 
# |_| |_| |_|\__,_| .__/  /_/\_\
#                 | |           
#                 |_|           
# Toolbox : analysis and process



#
# generate ui
#
observe({ 
  if(reactUser$allowToolbox){
    analysis <- input$selectAnalysis
    if(!noDataCheck(analysis)){
      v = reactMap$viewsData
      layers = lapply(v,function(x){x$layer})
      names(layers) = lapply(v,function(x){x$title})

      #
      # switch analaysis
      #
      out = NULL
      switch(analysis,
        "overlaps"={
          # prevent others layer to be evaluated.
          idA <- layers
          idB <- layers

          if(noDataCheck(idA) || noDataCheck(idB)){
            idA <- mxConfig$noData
            idB <- mxConfig$noData
          }
          # send ui
          out <- tagList(
            selectInput("selectOverlapA","Map to query",choices=idA,selected=idA[1]),
            selectInput("selectOverlapAVar","Variable to keep",
              choices="",
              multiple=TRUE),
            selectInput("selectOverlapB","Zone",choices=idB,selected=idB[1]),
            actionButton("btnAnalysisOverlaps",icon("play")),
            span(id="txtAnalysisOverlaps","") 
            )
          output$uiAnalysis <- renderUI(out)
        }
        )
    }
  }
})



# validation


observe({
  layA <- !noDataCheck(input$selectOverlapA)
  layB <- !noDataCheck(input$selectOverlapB)
  layAvar <- !noDataCheck(input$selectOverlapAVar)
  allowLaunchAnalysis <- FALSE
  if(all(c(layA,layB,layAvar))){
    allowLaunchAnalysis <- TRUE
  }
  mxActionButtonState(id="btnAnalysisOverlaps",disable=!allowLaunchAnalysis) 
})


observeEvent(input$btnAnalysisRemoveLayer,{
  
  if(reactUser$allowToolbox){
  idLayer = "analysis"
  proxyMap <- leafletProxy("mapxMap")
  proxyMap %>% 
  clearGroup(idLayer)
  }
    })

observe({
  if(reactUser$allowToolbox){
    selLayer <- input$selectOverlapA
    if(!noDataCheck(selLayer)){

      vars <- mxDbGetColumnsNames(selLayer)

      vars <- vars[!vars %in% c(
        mxConfig$vtInfo$geom,
        mxConfig$vtInfo$gid
        )]
      updateSelectInput(session,"selectOverlapAVar",choices=vars)
    }
  }
})

#
# OVERLAPS ANALYSIS  REQUEST
#
observeEvent(input$btnAnalysisOverlaps,{
  mxCatch(title="Overlaps analysis",{
  if(reactUser$allowToolbox){
    output$txtAnalysisOverlaps <- renderText("Launch analysis..")
    idLayer = "analysis"
    idA <- input$selectOverlapA
    idB <- input$selectOverlapB
    idAVar <- input$selectOverlapAVar
    if(!noDataCheck(idA) && !noDataCheck(idB)){
      # ASSUME THAT the same combination of layer will produce the same output.
      outName <- paste0("tmp__",digest(paste(idA,idB,idAVar)))
      mxUpdateText(id="txtAnalysisOverlaps",text="Launch analysis... This could a slow process, please be patient")



      #
      # Mmx overlap analysis
      #
      mxAnalysisOverlaps(
        inputBaseLayer = idA,
        inputMaskLayer = idB,
        outName,
        varToKeep=idAVar)

      mxUpdateText(id="txtAnalysisOverlaps",text="Analysis done! Update vector tiles...")
 
      if(mxDbExistsTable(outName)){

      mxUpdateText(id="txtAnalysisOverlaps",text="Vector tiles available, begin download.")
        proxyMap <- leafletProxy("mapxMap")
        proxyMap %>%
        addVectorTiles(
          userId         = reactUser$data$id,
          protocol       = mxConfig$vtInfo$protocol,
          host           = mxConfig$vtInfo$host,
          port           = mxConfig$vtInfo$port,
          geomColumn     = mxConfig$vtInfo$geom,
          idColumn       = mxConfig$vtInfo$gid,
          layer          = outName,
          dataColumn     = idAVar,
          onLoadFeedback = "always",
          group = "analysis"
          ) 
      }else{
        mxUpdateText(id="txtAnalysisOverlaps",text="something went wrong : layer computed but not available")
      }

    }
  }
      })
})


observe({

  mxCatch(title="Overlaps analysis, set style",{
    #
    # Style layer when loaded
    #
    grpClient <- input$leafletvtIsLoaded$grp
    layClient <- input$leafletvtIsLoaded$lay

    if(!noDataCheck(grpClient) && grpClient=="analysis"){
      mxUpdateText(id="txtAnalysisOverlaps",text="Layer rendered, add default style.")

      session$sendCustomMessage(
        type="setStyleDefault",
        list(
          group=grpClient
          )
        )
    }
      })
})


