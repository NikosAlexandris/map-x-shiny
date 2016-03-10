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
  if(mxReact$allowToolbox){
    analysis <- input$selectAnalysis
    if(!noDataCheck(analysis)){
      v = mxReact$views
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
            conditionalPanel(condition="(
              input.selectOverlapA != '' && 
              input.selectOverlapAVar != '' &&
              typeof(input.selectOverlapAVar) != 'undefined' &&
              input.selectOverlapB != ''
              )",
            actionButton("btnAnalysisOverlaps",icon("play")),
            span(id="txtAnalysisOverlaps","")
            )
          )
   output$uiAnalysis <- renderUI(out)
        }
      )
    }
  }
})


observeEvent(input$btnAnalysisRemoveLayer,{
  
  if(mxReact$allowToolbox){
  idLayer = "analysis"
  proxyMap <- leafletProxy("mapxMap")
  proxyMap %>% 
  clearGroup(idLayer)
  }
    })

observe({
  if(mxReact$allowToolbox){
    selLayer <- input$selectOverlapA
    if(!noDataCheck(selLayer)){

      vars <- vtGetColumns(
        protocol=mxConfig$protocolVt,
        table=selLayer,
        port=mxConfig$portVt
        )$column_name

      vars <- vars[!vars %in% c("geom","gid")]
      updateSelectInput(session,"selectOverlapAVar",choices=vars)
    }
  }
})

#
# OVERLAPS ANALYSIS  REQUEST
#
observeEvent(input$btnAnalysisOverlaps,{
  mxCatch(title="Overlaps analysis",{
  if(mxReact$allowToolbox){
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
        dbInfo=dbInfo,
        inputBaseLayer = idA,
        inputMaskLayer = idB,
        outName,
        varToKeep=idAVar)

      mxUpdateText(id="txtAnalysisOverlaps",text="Analysis done! Update vector tiles...")

      #
      # UPDATE PGRESTAPI
      #


      if( mxConfig$hostname != "map-x-full" ){
        print("update pgrestapi from darwin") 
        if(!exists('remoteInfo'))stop("No remoteInfo found in /settings/settings.R")
        r <- remoteInfo 
        mxDebugMsg("Command remote server to restart app")
        remoteCmd("map-x-full",cmd=mxConfig$restartPgRestApi)
        Sys.sleep(3)
      }else{
        print("update pgrestapi from not darwin")
        system(mxConfig$restartPgRestApi)
      }


      #
      # Add layer
      #

      layers <- vtGetLayers(
        protocol=mxConfig$protocolVt,
        port=mxConfig$portVt,
        grepExpr=paste0("^tmp_")
        )
      
      
      if(outName %in% layers){

      mxUpdateText(id="txtAnalysisOverlaps",text="Vector tiles available, begin download.")
        proxyMap <- leafletProxy("mapxMap")
        proxyMap %>%
        addVectorTiles(
          url=mxConfig$hostVt,
          port=mxConfig$portVtPublic,
          geomColumn="geom", # should be auto resolved by PGRestAPI
          idColumn="gid", # should be auto resolved by PGRrestAPI
          table=outName,
          dataColumn=idAVar,
          group = idLayer,
          onLoadFeedback="always"
          ) 
      }else{
        mxUpdateText(id="txtAnalysisOverlaps",text="something went wrong : layer computed but not available")
      }

    }
  }
      })
})


observe({
  #
  # Style layer when loaded
  #
  grpClient <- input$leafletvtIsLoaded$grp
  layClient <- input$leafletvtIsLoaded$lay
  
  if(!noDataCheck(grpClient) && grpClient=="analysis"){
    mxUpdateText(id="txtAnalysisOverlaps",text="Layer rendered, add default style.")
    jsCode <- sprintf("leafletvtId.analysis.setStyle(defaultStyle,'%s')",layClient)
    session$sendCustomMessage(
      type="jsCode",
      list(code=jsCode)
      )
  }
})


