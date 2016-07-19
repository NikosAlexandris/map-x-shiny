#                             
#  _ __ ___   __ _ _ __   __  __
# | '_ ` _ \ / _` | '_ \  \ \/ /
# | | | | | | (_| | |_) |  >  < 
# |_| |_| |_|\__,_| .__/  /_/\_\
#                 | |           
#                 |_|           
# Toolbox : analysis and process


#
# GET LAYER LIST
#
observe({ 
  layers <- c()
  if(reactUser$allowAnalysisOverlap){
    if(!noDataCheck(reactMap$viewsData)){
      v <- reactMap$viewsData
      # extract layer id
      layers <- sapply(v,function(x){x$layer})
      # set title
      names(layers) <- sapply(v,function(x){x$title})
    }
  }
  reactMap$analysisOverlapLayers <- layers
})

#
# UPDATE OPTION LIST A
#

observe({
  choices <- mxConfig$noData
  choices <- c(choices,reactMap$analysisOverlapLayers)
  updateSelectInput(session,inputId="selectOverlapA",choices=choices)
})

#
# UPDATE OPTION LIST B
#
observe({
  choices <- mxConfig$noData
  overlapA <- input$selectOverlapA 
  choicesAll <- reactMap$analysisOverlapLayers
  choices <- c(choices,choicesAll[!choicesAll %in% overlapA])
  updateSelectInput(session,inputId="selectOverlapB",choices=choices)
})

#
# UPDATE VARIABLES TO KEEP IN OVERLAP BASED ON A
#
observe({
  selLayer <- input$selectOverlapA
  if(reactUser$allowAnalysisOverlap){
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
# VALIDATION AND SHOW BUTTON
#
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

#
# REMOVE LAYER
#
observeEvent(input$btnAnalysisRemoveLayer,{
  
  proxyMap <- leafletProxy("mapxMap")
  proxyMap %>% 
  clearGroup( mxConfig$layerOverlap )
  
})


#
# OVERLAPS ANALYSIS  REQUEST
#
observeEvent(input$btnAnalysisOverlaps,{
  mxCatch(title="Overlaps analysis",{

  if(reactUser$allowAnalysisOverlap){

    output$txtAnalysisOverlaps <- renderText("Launch analysis..")
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
        outName        = outName,
        varToKeep      = idAVar
        )

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
          group          = mxConfig$layerOverlap
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

    if(!noDataCheck(grpClient) && grpClient==mxConfig$layerOverlap){
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


