
mxAnalysisOverlaps <- function(dbInfo,inputBaseLayer,inputMaskLayer,outName,dataOwner="mapxw",sridOut=4326,varToKeep="gid"){

  msg=character(0)
  if(!outName %in% mxDbListTable(dbInfo)){

    varToKeep <- paste0(sprintf("%s.%s",inputBaseLayer,varToKeep),collapse=",")
    createTable = sprintf("
      create table %1$s as SELECT %4$s, 
      ST_Multi(ST_Buffer(ST_Intersection(%3$s.geom, %2$s.geom),0.0)) As geom
      FROM %3$s
      INNER JOIN %2$s
      ON ST_Intersects(%3$s.geom, %2$s.geom)
      WHERE Not ST_IsEmpty(ST_Buffer(ST_Intersection(%3$s.geom, %2$s.geom),0.0));
      ALTER TABLE %1$s
      ALTER COLUMN geom TYPE geometry(MultiPolygon, %5$i) 
      USING ST_SetSRID(geom,%5$i);
      ALTER TABLE %1$s OWNER TO %6$s;
      ALTER TABLE %1$s ADD COLUMN gid BIGSERIAL PRIMARY KEY;
      ",
      outName,
      inputBaseLayer,
      inputMaskLayer,
      varToKeep,
      sridOut,
      dataOwner
      )

    mxDbGetQuery(dbInfo,createTable) 

    #
    # UPDATE PGRESTAPI
    #

    if(mxConfig$os=="Darwin"){
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

  }

 # if(outName %in% mxDbListTable(dbInfo)){
 #   q <- sprintf("SELECT * FROM %1$s;",outName)
 #   return(dbGetGeoJSON(dbInfo=dbInfo,query=q,fromSrid=sridOut,toSrid=sridOut))
 # }else{
 #   stop("No table created")
 # }
}





#
# EVENT LISTENER
#
observe({ 
  if(
    mxReact$allowViewsCreator &&
    isTRUE(mxReact$mapPanelMode == "mapViewsToolbox")
    ){
    observe({
      v = mxReact$views
      layers = lapply(v,function(x){x$layer})
      names(layers) = lapply(v,function(x){x$title})
      analyse <- input$selectAnalysis 
      if(!noDataCheck(analyse)){
        switch(analyse,
          #
          # OVERLAPS UI
          #
          "overlaps"=output$uiAnalysis<-renderUI({
            # prevent others layer to be evaluated.
            idA = layers[grep("_ext_mineral",layers)]
            idB = layers[grep("_env_",layers)]

            if(noDataCheck(idA) || noDataCheck(idB)){
              idA <- mxConfig$noData
              idB <- mxConfig$noData
            }
            # send ui
            tagList(
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
              actionButton("btnAnalysisOverlaps",icon("play")),
              span(id="txtAnalysisOverlaps","")
              )
            )
          })
        )

      }
    })


observe({
  selLayer <- input$selectOverlapA
  if(!noDataCheck(selLayer)){
    
     vars <- vtGetColumns(table=selLayer,port=mxConfig$portVt)$column_name
    vars <- vars[!vars %in% c("geom","gid")]
    updateSelectInput(session,"selectOverlapAVar",choices=vars)
  }
})

#
# OVERLAPS ANALYSIS  REQUEST
#
observeEvent(input$btnAnalysisOverlaps,{
  output$txtAnalysisOverlaps <- renderText("Launch analysis..")
  idLayer = "analysis"
  idA <- input$selectOverlapA
  idB <- input$selectOverlapB
  idAVar <- input$selectOverlapAVar
  if(!noDataCheck(idA) && !noDataCheck(idB)){
    # ASSUME THAT the same combination of layer will produce the same output.
    outName <- paste0("tmp__",digest(paste(idA,idB,idAVar)))
    mxUpdateText(id="txtAnalysisOverlaps",text="Launch analysis... This could a slow process, please be patient")
    mxAnalysisOverlaps(dbInfo,idA,idB,outName,varToKeep=idAVar)
    mxUpdateText(id="txtAnalysisOverlaps",text="Analysis done! Rendering...")
    layers <- vtGetLayers(port=mxConfig$portVt,grepExpr=paste0("^tmp_"))
    if(outName %in% layers){
      proxyMap <- leafletProxy("mapxMap")
      proxyMap %>%
      addVectorTiles(
        url=mxConfig$hostVt,
        port=mxConfig$portVtPublic,
        geomColumn="geom", # should be auto resolved by PGRestAPI
        idColumn="gid", # should be auto resolved by PGRrestAPI
        table=outName,
        dataColumn=idAVar,
        group = idLayer
        ) 
    }else{
      mxUpdateText(id="txtAnalysisOverlaps",text="Requested layer not available")
    }
    #   addGeoJSON(geojson=res,weight = 1, color = "#444444", fill = TRUE,options=list("zIndex"=20))

  }
    })
  }
})


observe({
  grpClient <- input$leafletvtStatus$grp
  layClient <- input$leafletvtStatus$lay
  if(!noDataCheck(grpClient) && grpClient=="analysis"){
    mxUpdateText(id="txtAnalysisOverlaps",text="Displaying result and set style.")
    jsCode <- sprintf("leafletvtId.analysis.setStyle(defaultStyle,'%s')",layClient)
    session$sendCustomMessage(
      type="jsCode",
      list(code=jsCode)
      )
  }
})


