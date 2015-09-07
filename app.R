
#source("fun.R")
source("loadlib.R")
source("fun/helperUi.R")
source("settings/settings.R")
source("config.R")

# NOTE : mvt exemple in Documents/unep_grid/map-x/test/Leaflet.MapboxVectorTile-master/examples/



#
# UI
#

ui <- tagList(
  tags$head(
    #
    # METAS
    #
    tags$meta(`http-equiv`="X-UA-Compatible",content="IE=edge"),
    tags$meta(name="viewport",content="width=device-width, initial-scale=1"),
    tags$meta(name="description", content=""),
    tags$meta(name="author", content=""),
    #
    #STYLE SHEET
    #
    tags$link(href="font-awesome-4.4.0/css/font-awesome.min.css",rel="stylesheet",type="text/css"),
    tags$link(href="theme/grayscale/bootstrap.min.css",rel="stylesheet",type="text/css"),
    tags$link(href="mapx/mapx.css",rel="stylesheet",type="text/css")
    ),
  tags$body(id="page-top",`data-spy`="scroll",`data-target`=".navbar-fixed-top", `data-offset`="0",
    #
    # PANELS
    #
    # 
    # SECTIONS
    #
    loadUi('parts/ui/nav.R'),
    loadUi('parts/ui/intro.R'),
    loadUi('parts/ui/about.R'),
    loadUi('parts/ui/country.R'),
    loadUi('parts/ui/map.R'),
    loadUi('parts/ui/footer.R')
    ),
  #
  # Scripts
  #
  tags$head(
    tags$script(src="chartjs/Chart.min.js"),
    tags$script(src="mapx/mapxChartJsConf.js"),
    tags$script(src="theme/grayscale/grayscale.js"),
    tags$script(src="theme/grayscale/jquery.easing.min.js"),
    tags$script(src="bootstrap/js/bootstrap.min.js"),
    tags$script(src="mapx/mapx.js")
    )
  )





#
# Server
#
server <- function(input, output, session) {

  mxReact <- reactiveValues()
  mxStyle <- reactiveValues()


  # load parts

  source('parts/server/country.R',local=TRUE)
  source('parts/server/upload.R',local=TRUE)

  # set reactive values


  #
  # show debugger
  #
  observeEvent(input$btnDebug,{
    browser()
  })


  
 #
  # URL parsing
  #
#  observe({
#    query <- parseQueryString(session$clientData$url_search)
#    if(isTRUE(query$country %in% mxConfig$countryListChoices$pending || query$country %in% mxConfig$countryListChoices$potential)){
#      sel = query$country
#    }else{
#      sel = "AFG"
#    }
#    updateSelectInput(session,'selectCountry',selected=sel,choices=mxConfig$countryListChoices)
#  })
  #
  observe({
    mxCatch(title="Query url",{
      query <- parseQueryString(session$clientData$url_search,nested=TRUE)
      if(isTRUE(query$country %in% mxConfig$countryListChoices$pending || query$country %in% mxConfig$countryListChoices$potential)){
        sel = query$country
      }else{
        sel = "AFG"
      }
      updateSelectInput(session,'selectCountry',selected=sel,choices=mxConfig$countryListChoices)
      if(!is.null(query$views)){
        views <- unlist(strsplit(subPunct(query$views,";"),";"))
        if(!noDataCheck(views)){
          isolate({
          mxReact$viewsFromUrl <- unique(views)
          })
        }
      }
    })
  })


  #
  # Populate views list TODO: add filter on desc,title,class,....
  #
  observe({
    mxCatch(title="Populate views from db",{
    cntry <- mxReact$selectCountry
    update <- mxReact$viewsListUpdate
    views = list()
    if(!noDataCheck(cntry)){
      viewsDf <- mxGetViewsList(dbInfo,mxConfig$viewsListTableName,country=cntry)
      if(nrow(viewsDf)>0){
        # create list of map views
        for(i in viewsDf$id){
          views[[i]] <- as.list(viewsDf[viewsDf$id==i,])
          views[[i]]$style <- fromJSON(views[[i]]$style)
        }
        #mxDebugMsg(sprintf("%s map views retrieved for country %s",length(views),cntry))
      }
        mxReact$views <- views
    }
    })
  })



  #
  # Html construction
  #
  observe({
    mxCatch(title="HTML views construction",{
    v <- mxReact$views
    if(!is.null(v)){

      cl = mxConfig$class
      cl = data.frame(n=names(cl),id=as.character(cl),stringsAsFactors=FALSE)

      clUn = unique(sapply(v,function(x)x$class))

      
      viewsList = list()
      for(i in names(v)){
        title = v[[i]]$title 
        class = v[[i]]$class
        className = cl[cl$id == class,'n']
        viewId = as.list(i)
        names(viewId) = title
        other = viewsList[[className]]
        if(is.null(other)){
          viewsList[[className]] <- viewId
        }else{
          viewsList[[className]] <- c(viewId,other)
        }
      }

     id = "viewsFromMenu"

     checkList = tagList()

     for(i in names(viewsList)){
       items <- viewsList[[i]]
       checkList <- tagList(checkList,tags$span(class="map-views-class",i))
       for(j in names(items)){
         it <- items[j]
         val <- div(class="checkbox",
           tags$label(
           tags$input(type="checkbox",class="vis-hidden",name=id,value=as.character(it)),
            div(class="map-views-item",
             tags$span(class='map-views-selector',names(it))
             )
             )
           )
         checkList <- tagList(checkList,val)
       }
     }

     checkListOut <- tagList(
       div(id=id,class="form-group shiny-input-checkboxgroup shiny-input-container",
         div(class="shiny-options-group",
           checkList
           )
         )
       )


     output$checkInputViewsContainer <- renderUI(checkListOut)

    }
    })
  })


  #
  # Views manager
  #


  observe({
    mxCatch(title="Views manager",{
      vUrl = mxReact$viewsFromUrl
      vMenu = input$viewsFromMenu
      vAvailable = names(mxReact$views) 
      vToDisplay = NULL
      if(!noDataCheck(vAvailable)){  
        if(noDataCheck(vMenu) && !noDataCheck(vUrl)){
          vToDisplay = vUrl[vUrl %in% vAvailable]
        }else if(!noDataCheck(vMenu)){
          vToDisplay =  vMenu[vMenu %in% vAvailable]
        }else{
          vToDisplay = mxConfig$noData
        }
        if(!is.null(vToDisplay)){ 
          mxDebugMsg(paste("view manager. View to display:",paste(vToDisplay,collapse=", ")))
          mxReact$viewsToDisplay <- vToDisplay
          mxReact$viewsFromUrl=NULL
        }
      }
       })
  })



  #
  # New view
  #

  source("parts/server/creator.R",local=T)

  #
  # Queuing system
  #

  


  # add vector tiles
  observeEvent(mxReact$viewsToDisplay,{
    mxCatch(title="Display selected views",{
# begin 


  # reactive values
    vData = mxReact$views    
    vToDisplay = mxReact$viewsToDisplay
    vDisplayed = input$mapxMap_groups
    vProcessed = input$leafletvtViews

    cat(paste(paste0(rep("-",80),collapse=""),"\n"))
    mxDebugMsg("Begin layer Manager")
    mxDebugMsg(paste("views to display:",paste(vToDisplay,collapse=";")))
    start = Sys.time()
  
    # evaluate
    vAll = names(vData) 
    vDisplayed = vDisplayed[vDisplayed %in% vAll]
    vToHide = vDisplayed[! vDisplayed %in% vToDisplay]

    vToShow = vToDisplay[vToDisplay %in% vProcessed]
    vToShow = vToShow[!vToShow %in% vDisplayed]

    vToCalc =  vToDisplay[!vToDisplay %in% vProcessed][1]
    
    
    if(!noDataCheck(vToCalc)){
     sty <- vData[[vToCalc]]$style
      if(!noDataCheck(sty)){
        mxDebugMsg(paste("First style computation for",vToCalc))
        mxStyle$layer = sty$layer
        mxStyle$group = vToCalc
        mxStyle$variable = sty$variable
      }
    return()
    }

    if(!noDataCheck(vToShow)){
      mxDebugMsg(paste("Activate",vToShow))
      legendId = sprintf("%s_legends",vToShow)
      proxyMap <- leafletProxy("mapxMap")
      sty <- vData[[vToShow]]$style
      leg <- sty$hideLegends

      if(!leg){
        tit <- sty$title
        pal <- sty$palette
        val <- sty$values

        sty<-addPaletteFun(sty,pal)
        palFun = sty$paletteFun

        mxDebugMsg(sprintf("Add legend in layer id %s", legendId))
        proxyMap %>%
        showGroup(as.character(vToShow)) %>%
        addLegend(position="topright",pal=palFun,values=val,title=tit,layerId = legendId)
      }else{
        proxyMap %>%
        showGroup(as.character(vToShow))
      }
      return()
    }

    if(!noDataCheck(vToHide)){
    mxDebugMsg(paste("hide",vToHide))
    legendId = sprintf("%s_legends",vToHide)
    proxyMap <- leafletProxy("mapxMap")
    proxyMap %>% 
    hideGroup(as.character(vToHide)) %>%
    removeControl(legendId)
    return()
    }
    

    stop = Sys.time() - start
    mxDebugMsg(paste("End of vector tiles manager. Timing=",stop))
    cat(paste(paste0(rep("-",80),collapse=""),"\n"))
   })
  })


  # on tile loaded, set style
  observeEvent(input$leafletvtStatus,{
    mxCatch(title="Set style object after tiles loaded",{
      lay = input$leafletvtStatus$lay
      grp = input$leafletvtStatus$grp
      vData = mxReact$views

      if(isTRUE(!noDataCheck(grp) && !noDataCheck(lay))){
        sty <-vData[[grp]]$style
        if(!noDataCheck(sty)){
          mxStyle$scaleType <- sty$scaleType
          mxStyle$title <- sty$title
          mxStyle$variable <- sty$variable
          mxStyle$values <- sty$values
          mxStyle$palette <- sty$palette
          mxStyle$paletteChoice <-  mxConfig$colorPalettes
          mxStyle$opacity <- sty$opacity
          mxStyle$basemap <- sty$basemap
          mxStyle$size <- sty$size
          mxStyle$hideLabels <- sty$hideLabels
          mxStyle$hideLegends <- sty$hideLegends
        }
      }
   })
  })


#
#  observeEvent(input$mapxMap_zoom,{
#    vis = input$leafletvtVisible
#    vis = vis[vis=TRUE]
#
#  if(!noDataCheck(vis)){
#    setLayerZIndex(zIndex(100))  
#  }
#  })
#


#
#  observe({
#
#   # mxDebugMsg('Update queuing system')
#    vToDisp <- mxReact$viewsToDisplay
#    vDisp <- names(input$leafletvtGroups)
#    isolate({
#      if(!isTRUE(vToDisp == mxConfig$noData)){
#        vData <- mxReact$views
#        vId <- vToDisp[ ! vToDisp %in% vDisp ][1] 
#
#        if(!noDataCheck(vId)){ 
#          view <- vData[[vId]]
#          sty <- view$style
#          if(!noDataCheck(sty)){
#            mxDebugMsg(paste("view id processed=",vId))
#            mxStyle$update <- runif(1)
#            mxStyle$layer <- sty$layer
#            mxStyle$group <- vId
#
#                      print( str(reactiveValuesToList(mxStyle)))
#          }
#        }
#      }
#
#      vToRemove <- vDisp[! vDisp %in% vToDisp]
#      if(!noDataCheck(vToRemove)){ 
#        legendId = sprintf("%s_legends",vToRemove)
#        mxDebugMsg(paste("groups register to be cleaned ",paste(vToRemove,collapse=",")))
#        proxyMap <- leafletProxy("mapxMap") 
#        proxyMap %>%
#        removeVectorTiles(vToRemove) %>%
#        removeControl(legendId)
#      }
#
#    })
#
#  })
#

#  
#  observeEvent(input$ftutjlpdrriwgkdoxrq,{
#    mxDebugMsg("Action link : update layer")
#    vId <- "ftutjlpdrriwgkdoxrq"
#    mL <- mxReact$viewsList
#    vS <- mL[mL$id==vId,]
#    sty = fromJSON(vS$style)
#    if(!noDataCheck(sty)){
#      mxStyle$scaleType <- sty$scaleType
#      mxStyle$title <- sty$title
#      mxStyle$layer <- sty$layer
#      mxStyle$variable <- sty$variable
#      mxStyle$values <- sty$values
#      mxStyle$palette <- sty$palette
#      mxStyle$paletteChoice <-  mxConfig$colorPalettes
#      mxStyle$opacity <- sty$opacity
#      mxStyle$basemap <- sty$basemap
#      mxStyle$size <- sty$size
#      mxStyle$hideLabels <- sty$hideLabels
#      mxStyle$hideLegends <- sty$hideLegends
#      mxStyle$group <- "group_002"
#    }
#  })
#



  #
  # Config panel event handling
  #
  
  # wms
  observe({
    mxCatch(title="Add wms service",{
    wms <- input$txtConfigAddWms
    if(!noDataCheck(wms)){
    
    
    }
   })
  })



  #
  # set map panel mode TODO: clean this. Mode is stored in a visible javascrip object : not secure.
  #


  mxCatch(title="set panel mode",{
    # default
    output$titlePanelMode <- renderText({
      mxSetMapPanelMode(mode='mapViewsExplorer',title='Map view explorer')$title
    })

    # Creator mode
    observeEvent(input$btnViewsCreator,{
      panelMode = mxSetMapPanelMode(mode='mapViewsCreator',title='Map views creator')
      mxReact$mapPanelTitle = panelMode$title
      mxReact$mapPanelMode  = panelMode$mode
    })

    # explorer mode
    observeEvent(input$btnViewsExplorer,{
      panelMode = mxSetMapPanelMode(mode='mapViewsExplorer',title='Map views explorer')
      mxReact$mapPanelTitle <- panelMode$title
      mxReact$mapPanelMode  <- panelMode$mode
    })

    # explorer mode
    observeEvent(input$btnViewsConfig,{
      panelMode = mxSetMapPanelMode(mode='mapViewsConfig',title='Map views config')
      mxReact$mapPanelTitle <- panelMode$title
      mxReact$mapPanelMode  <- panelMode$mode
    })



    observe({ 
      title <- mxReact$mapPanelTitle
      if(noDataCheck(title))return()
      output$titlePanelMode <- renderText({title}) 
    })


  })
  #
  # MAIN MAP
  #


  output$mapxMap <- renderLeaflet({
    group = "main"
    iso3 <- mxReact$selectCountry
    if(!noDataCheck(iso3)){
    center <- mxConfig$countryCenter[[iso3]]
    switch(iso3,
      "COD"={
        leaflet() %>%
        clearGroup(group) %>%
        addTiles(
          'http://localhost:3030/services/tiles/cod_base_layer_0_6/{z}/{x}/{y}.png',
          group=group,
          options=list(
            'zIndex'=0,
            'minZoom'=0,
            'maxZoom'=6)
          ) %>%  
        addTiles(
          'http://localhost:3030/services/tiles/cod_base_layer_7_10/{z}/{x}/{y}.png',
          group=group,
          options=list(
            'zIndex'=0,
            'minZoom'=7,
            'maxZoom'=10)
          ) %>%
        setView(center$lng,center$lat,center$zoom)
      },
      'AFG'={
        leaflet() %>%
        clearGroup(group) %>%
        addTiles(
          'http://localhost:3030/services/tiles/afg_base_layer/{z}/{x}/{y}.png',
          group=group
         )%>% setView(center$lng,center$lat,center$zoom)
      } 
      )
    }
  })


#
#
#
#  observe({
#  print(input$leafletvtStatus)
#  })
#
#
#

  #
  # Add vector tiles
  #

  observe({ 
    mxCatch(title="Add vector tiles",{
      grp <- mxStyle$group
      lay <- mxStyle$layer

      mapViewMode <- isolate(mxReact$mapPanelMode) 
      if(is.null(mapViewMode))mapViewMode="mapViewsExplorer" # TODO: set default for mxReact$mapPanelMode 
      if(!noDataCheck(lay)){
        mxDebugMsg(paste("Ready to add vector tiles in group",grp))
        isolate({
          if(mapViewMode == "mapViewsCreator"){
            vars <- vtGetColumns(table=lay,port=3030)$column_name
          }else{
            vars <- c(mxStyle$variable)
          }
        })
        if(!noDataCheck(vars)){       
          proxyMap <- leafletProxy("mapxMap")
          proxyMap %>%
          #removeVectorTiles(grp) %>%
          addVectorTiles(
            url="localhost",
            port=3030,
            geomColumn="geom", # should be auto resolved by PGRestAPI
            idColumn="gid", # should be auto resolved by PGRrestAPI
            table=lay,
            dataColumn=vars,
            group = grp
            )  
          mxDebugMsg(paste("Start downloading",grp))
        }
      }
      })
  })



  #
  # Set map center based on center of layer
  #


  observeEvent(input$btnZoomToLayer,{
    mxCatch(title="Btn zoom to layer",{
      lay <- mxStyle$layer
      if(noDataCheck(lay))return()
      zm = mxConfig$countryCenter[[mxReact$selectCountry]]$zoom
      centro<-dbGetLayerCentroid(dbInfo=dbInfo,table=lay)
      if(noDataCheck(centro)){
        centro <- list(lng=0,lat=0)
      }
      proxyMap <- leafletProxy("mapxMap")
      proxyMap %>%
      setView(lng=centro$lng, centro$lat, zm)
      })
  })


 #
  # Additional base map
  #


  observe({
    mxCatch(title="Additional base map",{
      layId = "basemap"
      selBaseMap <- mxStyle$basemap 
      if(noDataCheck(selBaseMap)) return()
      proxyMap <- leafletProxy("mapxMap")

      if(selBaseMap==mxConfig$noLayer){
        mxDebugMsg("Remove additional base layer if needed")
        proxyMap %>%
        removeTiles(layerId=layId)
      }else{
        mxDebugMsg("Set additional base layer")
        if(! selBaseMap == "mapbox"){
          proxyMap %>%
          removeTiles(layId) %>%
          addProviderTiles(selBaseMap,layerId=layId,options=list('zIndex'=10))
        }else{
          proxyMap %>%
          removeTiles(layId) %>%
          addTiles(
            "https://api.mapbox.com/v4/mapbox.satellite/{z}/{x}/{y}.png?access_token=pk.eyJ1IjoiaGVsc2lua2kiLCJhIjoiMjgzYWM4NTE0YzQyZGExMTgzYTJmNGIxYmEwYTQwY2QifQ.dtq8cyvJFrJSUmSPtB6Q7A"
            ,layerId=layId,options=list('zIndex'=10))
        }
      }
      })
  })


  observe({
    mxCatch(title="Set layer 'labels'",{
      group = "labels"
      hideLabels <- mxStyle$hideLabels
      iso3 <- mxReact$selectCountry
      if(!noDataCheck(hideLabels) && !noDataCheck(iso3)){
        proxyMap <- leafletProxy("mapxMap")
        if(!hideLabels){ 
          switch(iso3,
            "COD"={
              proxyMap %>%
              clearGroup(group) %>%
              addTiles(
                'http://localhost:3030/services/tiles/cod_labels_0_6/{z}/{x}/{y}.png',
                group=group,
                options=list(
                  'zIndex'=30,
                  'minZoom'=0,
                  'maxZoom'=6)
                ) %>%  addTiles(
                "http://localhost:3030/services/tiles/cod_labels_7_10/{z}/{x}/{y}.png;",
                group=group,
                options=list(
                  'zIndex'=30,
                  'minZoom'=7,
                  'maxZoom'=10)
                )
            },
            'AFG'={
              proxyMap %>%
              clearGroup(group) %>%
              addTiles(
                'http://localhost:3030/services/tiles/afg_labels/{z}/{x}/{y}.png',
                group=group,
                options=list(
                  zIndex=30
                  )
                )
            } 
            )
        }else{
          proxyMap %>%
          clearGroup(group)
        }
      }
      })
  })

  #
  #  Set layer colors
  #
  layerStyle <- reactive({
    mxCatch(title="Set reactive function for style",{
      #up <- mxStyle$update
      sty <- reactiveValuesToList(mxStyle)
      palOk <- isTRUE(sty$palette %in% sty$paletteChoice)
      if(!any(sapply(sty,noDataCheck)) && palOk){ 
        sty <- addPaletteFun(sty,sty$palette)
        sty$colors <- sty$paletteFun(sty$values)
        return(sty)
      }else{
        return()
      }
      })
  })




  # 
  # Update layer color and legend
  # 


  #observe({
  observeEvent(input$leafletvtStatus,{
    mxCatch(title="Update layer style",{
    sty <- layerStyle()

    status = input$leafletvtStatus

    vtOk = sty$group == status$grp && grep(sty$layer,status$lay)>0
      if(!noDataCheck(sty) && !any(sapply(sty,is.null)) && vtOk){

    mxDebugMsg("Update layer style")
        tit <- sty$title
        col <- sty$colors
        pal <- sty$paletteFun
        val <- sty$values
        var <- sty$variable
        lay <- sty$layer
        opa <- sty$opacity
        sze <- sty$size
        grp <- sty$group
        leg <- sty$hideLegends
        bnd <- sty$bounds
        mxDebugMsg("Begin style")
        start = Sys.time()
        legendId = sprintf("%s_legends",grp)
        proxyMap <- leafletProxy("mapxMap")
        if(is.null(tit))tit=lay
        if(!leg){
          mxDebugMsg(sprintf("Add legend in layer id %s", legendId))
            proxyMap %>%
            addLegend(position="topright",pal=pal,values=val,title=tit,layerId = legendId)
        }else{
          mxDebugMsg(sprintf("Remove legend layer id %s", legendId))
          proxyMap %>%
          removeControl(legendId)
        }
        
        names(col) <- val
        jsColorsPalette <- sprintf("var colorsPalette=%s; console.log(colorsPalette);",toJSON(col,collapse=""))
        jsDataCol <- sprintf("var dataColumn ='%s' ;",var)
        jsOpacity <- sprintf("var opacity =%s ;",opa)
        jsSize <- sprintf("var size =%s; ", sze)
        jsUpdate <- sprintf("leafletvtGroup.%s.setStyle(updateStyle,'%s');",grp,paste0(lay,"_geom"))

        jsStyle = "updateStyle = function (feature) {
        var style = {};
        var selected = style.selected = {};
        var type = feature.type;
        var defaultColor = 'rgba(0,0,0,0)';
        var dataCol = defaultColor;
        var val = feature.properties[dataColumn];
        if( typeof(val) != 'undefined'){ 
          var dataCol = hex2rgb(colorsPalette[val],opacity);
          if(typeof(dataCol) == 'undefined'){
            dataCol = defaultColor;
          }
        }
        switch (type) {
          case 1: //'Point'
          style.color = dataCol;
          style.radius = size;
          selected.color = 'rgba(255,255,0,0.5)';
          selected.radius = 6;
          break;
          case 2: //'LineString'
          style.color = dataCol;
          style.size = size;
          selected.color = 'rgba(255,25,0,0.5)';
          selected.size = size;
          break;
          case 3: //'Polygon'
          style.color = dataCol;
          style.outline = {
            color: dataCol,
            size: 1
          };
          selected.color = 'rgba(255,0,0,0)';
          selected.outline = {
            color: 'rgba(255,0,0,0.9)',
            size: size
          };
          break;
        };
        return style;

      };
      "
     # jsStyle = "updateStyle = function(){s={};s.color=randomHsl(0.8); return s;};"
      jsTimeBefore = "var d= new Date(); console.log('Time before style' + d + d.getMilliseconds());"
      jsTimeAfter = "var d= new Date(); console.log('Time after style' + d + d.getMilliseconds());"
      jsCode = paste(
        jsColorsPalette,
        jsDataCol,
        jsOpacity,
        jsSize,
        jsStyle,
        jsUpdate
        )

     
      session$sendCustomMessage(type="jsCode",list(code=jsTimeBefore))
      session$sendCustomMessage(type="jsCode",list(code=jsCode))
      session$sendCustomMessage(type="jsCode",list(code=jsTimeAfter))

#      setLayerZIndex(group=grp,zIndex=15)
      stop <- Sys.time() - start
      mxDebugMsg(paste("End style. Timing=",stop))
      cat(paste(paste0(rep("-",80),collapse=""),"\n"))
    }
  })
})



  observeEvent(input$btnMapCreatorSave,{
    mxCatch(title="Save style",{
      sty <- reactiveValuesToList(mxStyle)
      tableName <- mxConfig$viewsListTableName
      d <- dbInfo
      drv <- dbDriver("PostgreSQL")
      con <- dbConnect(drv, dbname=d$dbname, host=d$host, port=d$port,user=d$user, password=d$password)

      tryCatch({
        tableAppend = isTRUE( tableName %in% dbListTables(con))
        tbl = as.data.frame(stringsAsFactors=FALSE,list(
            id =  randomName(),
            country = mxReact$selectCountry,
            title = input$mapViewTitle,
            class = input$mapViewClass,
            layer = sty$layer,
            editor = "f@fxi.io",
            reviever = "f@fxi.io",
            revision = 0,
            validated = TRUE,
            archived = FALSE,
            dateCreated = date(),
            dataModifed = date(),
            dateValidated = date(),
            dateVariableMax = max(input$mapViewDateRange),
            dateVariableMin = min(input$mapViewDateRange),
            style = toJSON(sty,collapse="")
            )
          )
        dbWriteTable(con,tableName,value=tbl,append=tableAppend,row.names=F)
      },finally=dbDisconnect(con)
      )

      mxDebugMsg(sprintf("Write style %s in table %s", tbl$id, tbl$layer))
      mxReact$viewsListUpdate <- runif(1)
      output$txtValidationCreator = renderText({"ok."})
  })
})

}


mxCatch(title="Main application",{
  shinyApp(ui, server)
})
#
  # Get click feedback
  #
  #    output$outCoordinates <- renderUI({
  #      res <- input$mapxMap_click
  #      isolate({
  #        resOut <-dbGetValByCoord(dbInfo,table=input$selLayer,column=input$selColumn,lat=res$lat,lng=res$lng)
  #      })
  #      HTML(listToHtml(resOut,h=5))
  #    })
  #



#  observe({
#    mxDebugMsg(input$mapxMap_bounds)
#  })
#



# test
#if(FALSE){
#  spatialObj<-dbGetSp(dbInfo=d,"SELECT * FROM wdpa_afg_polygons_webmercator")
#  test<-dbGetGeoJSON(dbInfo=d,"SELECT * FROM wdpa_afg_polygons_webmercator")
#  drv <- dbDriver("PostgreSQL")
#  dbCon<- dbConnect(drv,host="129.194.205.12",dbname="mapx",user="mapxowner",password="opengeox",port=5432)
#  dbCon<- dbConnect(drv,host="129.194.205.12",dbname="mapx",user="postgres",password="opengeox",port=5432)
#  tableList<-dbListTables(dbCon)
#  for(i in tableList){
#    a=dbGetQuery(dbCon,sprintf("SELECT UpdateGeometrySRID("public", "%s", "geom", 4326) ;",i))
#  }
#  test<-dbGetQuery(dbCon,"SELECT * FROM afg__displaced_from__2013__a")
#}
#
#uiIntro_orig <- tagList(
#  #
#  # HEADER
#  #
#  tags$header(class="intro",
#    div(class="intro-body",
#      div(class="container",
#        div(class="row",
#          div(class="col-md-8 col-md-offset-2",
#            h1(class='brand-heading',"MAP-X"),
#            hr(),
#            tags$p(class="intro-text",
#              "Mapping and Assessing the Performance of Extractive Industries in Emerging Economies and Fragile States."
#              ),
#            hr(),
#            tags$p(tags$img(src="img/logo_grid_white_en.svg",style="height:100px;")),
#            hr()
#            )
#          )
#        )  
#      )
#    )
#  )


#
#
#
#  ui_orig <- tagList(
#    tags$head(
#      tags$link(href="font-awesome-4.4.0/css/font-awesome.min.css",rel="stylesheet",type="text/css"),
#      tags$link(href="theme/greyscale/grayscale.css"),
#      tags$link(href="theme/greyscale/bootstrap.min.css"),
#      tags$link(href="mapx/mapx.css",rel="stylesheet",type="text/css")
#      ),
#    #
#    # NAVIGATION
#    #
#    #
#    #  tags$div(class="top_country_select",
#    #    ),
#
#
#    #  selectInput("selectCountry","Select an EITI country",choices=mxConfig$countryListChoices),
#
#    tags$a(id="menu-toggle",href="#",class="btn btn-dark btn-lg toggle",icon("bars")),
#    tags$nav(id="sidebar-wrapper",
#      tags$ul(class="sidebar-nav",
#        tags$a(id="menu-close",href="#", class="btn btn-light btn-lg pull-right toggle",icon("times")),
#        tags$li("Navigation",
#          tags$ul(class="sidebar-sublist",
#            tags$li(class="sidebar-brand",tags$a(href="#top", "Map-x")),
#            tags$li(tags$a(href="#about","About")),
#            tags$li(tags$a(href="#country","Country data")),
#            tags$li(tags$a(href="#map","Map")),
#            tags$li(tags$a(href="#contact","Contact")),
#            )
#          ),
#        tags$li('Country selection',
#          selectInput("selectCountry","Select an EITI country",choices=mxConfig$countryListChoices)
#          # mxConfig$countryListHtml
#          )
#        )
#      ),
#
#    #
#    # ALERTS 
#    #
#    uiOutput("panelAlert"),
#    #
#    # HEADER
#    #
#    tags$header(id="top",class="header",
#      div(class="text-vertical-center big-title-container",
#        div(class="row",
#          div(class="col-md-8 col-md-offset-2",
#            h1(class='brand-heading',"MAP-X"),
#            hr(),
#            tags$p(class="intro-text",
#              "Mapping and Assessing the Performance of Extractive Industries in Emerging Economies and Fragile States."
#              ),
#            hr(),
#            tags$p(tags$img(src="img/logo_grid_white_en.svg",style="height:100px;")),
#
#            hr(),
#            tags$a(href="#map",class="btn btn-circle page-scroll",
#              tags$i(class="fa fa-globe animated")
#              ),
#            tags$a(href="#charts",class="btn btn-circle page-scroll",
#              tags$i(class="fa fa-bar-chart animated")
#              ),
#            tags$a(href="#map",class="btn btn-circle page-scroll",
#              tags$i(class="fa fa-map-o animated")
#              ),
#            tags$a(href="#map",class="btn btn-circle page-scroll",
#              tags$i(class="fa fa-plus animated")
#              ),
#            tags$a(href="#about",class="btn btn-circle page-scroll",
#              tags$i(class="fa fa-info animated")
#              )
#            )
#          )
#        )
#      ),
#
#    #
#    # COUNTRY INFO
#    #
#    tags$section(id="charts",class="about",
#      div(class="container"),
#      div(class="row",
#        div(class="col-lg-12 text-center",
#          div(class="col-lg-10 col-lg-offset-1",
#            h2("Country indicators"),
#            hr(class="small"),
#            fluidRow(
#              column(width=6,
#                p("")
#                #selectInput("selectCountry","Select an EITI country",choices=mxConfig$countryListChoices)
#                ),
#              column(width=6,
#                tabsetPanel(type="pills",
#                  tabPanel('Ressource gouvernance index',
#                    tags$canvas(id="testChart",width="500px",height="300px")
#                    ),
#                  tabPanel("World bank indicators", 
#                    tags$canvas(id="testChart2",width="500px",height="300px")
#                    )
#                  )
#                )
#              )
#            )
#          )
#        )
#      ),
#    #
#    # MAP
#    #
#    tags$section(id="map",class="about",
#      div(class="container"),
#      div(class="row",
#        div(class="col-lg-12 text-center",    
#          leafletOutput("mapxMap",height="400px")
#          )
#        )
#      ),
#    #
#    # MAP CREATOR
#    #
#    tags$section(id="map",class="about",
#      div(class="container"),
#      div(class="row",
#        div(class="col-lg-12 text-center",
#          h2("Map Creator"),
#          div(style="zoom:0.8",
#            selectInput("selectBaseMap","Select a base map",choices=mxConfig$tileProviders),
#            selectInput("selLayer","Select a vector tiles layer",choices="",selected=""),
#            selectInput("selColumn","Select a column",choices="",selected=""),
#            numericInput("sliderZoom","Set zoom",min=5,max=19,value=8,step=1),
#            #sliderInput("sliderZoom","Zoom",min=5,max=19,value=8,step=1),
#            numericInput("sliderOpacity","Opacity",min=0,max=1,value=0.2,step=0.2),
#            #sliderInput("sliderOpacity","Opacity",min=0,max=1,value=0.2,step=0.2),
#            uiOutput("outCoordinates")
#            )
#          )
#        )
#      ),
#    #
#    # ABOUT
#    #
#    tags$section(id="about",class="about",
#      div(class="container"),
#      div(class="row",
#        div(class="col-lg-12 text-center",
#          p("")
#          )
#        )
#      ),
#
#    #
#    #
#    #
#
#    #
#    # Scripts
#    #
#
#    # custom mapx script
#    includeScript("www/mapx/mapx.js"),
#
#    # chart js 
#    includeScript("www/chartjs/Chart.min.js"),
#
#    # grayscale theme
#    includeScript("www/theme/grayscale/grayscale.js"),
#    includeScript("www/theme/grayscale/jquery.easing.min.js")
#
#
# 
#
#    )

#
# hr(),
#          radioButtons('radioBtnYearSpanType',
#            inline=TRUE,
#            label="Choose year span method",
#            choices=c("Use slider"="yearSlider","Use layer column"="yearColumn")
#            ),
#          conditionalPanel(condition="input.radioBtnYearSpanType == 'yearSlider'",  
#          sliderInput("sliderYearSpan","Set year span",min=1950,max=2015,round=TRUE,sep="",value=c(1980L,2010L),ticks=1)
#            ),
#          conditionalPanel(condition="input.radioBtnYearSpanType == 'yearColumn'",
#           selectInput("columnYearSpan","Select a column containing the years", choices="")
#            ),
#          uiOutput("outCoordinates")
#

  #
  #    mxUpdatePanel(
  #      panelId="panelMain",
  #      title="MAP-X",
  #      subtitle="This is the technical proof of concept version of map-x",
  #      background=F,
  #      hideCloseButton=T,
  #      draggable=F,
  #      style="top:0px; left:0px;bottom=0px; width:500px; height:100%; height:100vh; z-index:10; opacity:0.94",
  #      html=list(
  #        div(style="zoom:1",
  #          selectizeInput(
  #            inputId="selectCountry",
  #            label="Select a country",
  #            choices=mxConfig$countryList),
  #          tabsetPanel(type="pills",
  #            tabPanel(p('Narratives'),
  #              h4('Ressource gouvernance index'),
  #              p('Hallo'),
  #              tags$canvas(id="testChart",width="500px",height="50%"),
  #              p('test')
  #              ),
  #            tabPanel(p("World bank indicators"),tagList(
  #                selectizeInput(
  #                  inputId="selectIndicator",
  #                  label="Select an indicator",
  #                  choices=mxConfig$wdiIndicators,
  #                  selected="NY.GDP.PCAP.KD"
  #                  ),
  #                dygraphOutput("dyGraphWdi")
  #                ))
  #            )
  #          )
  #        ),
  #      listActionButton=list( 
  #        actionButton("btnDebug","debug"),
  #        actionButton("btnShowMapCreator","map creator")
  #        )
  #      )
  #
  #    observeEvent(input$btnShowMapCreator,{ 
  #      mxTogglePanel(id="panelModal")
  #      })
  #
  #
  #    mxUpdatePanel(
  #      panelId = "panelModal",
  #      title = "Map creator",
  #      subtitle= "Set layer, base map and settings for the new map",
  #      background=F,
  #      style="display:none",
  #      html=list(
  #        div(style="zoom:0.8",
  #          selectInput("selectBaseMap","Select a base map",choices=mxConfig$tileProviders),
  #          selectInput("selLayer","Select a vector tiles layer",choices="",selected=""),
  #          selectInput("selColumn","Select a column",choices="",selected=""),
  #          numericInput("sliderZoom","Set zoom",min=5,max=19,value=8,step=1),
  #          #sliderInput("sliderZoom","Zoom",min=5,max=19,value=8,step=1),
  #          numericInput("sliderOpacity","Opacity",min=0,max=1,value=0.2,step=0.2),
  #          #sliderInput("sliderOpacity","Opacity",min=0,max=1,value=0.2,step=0.2),
  #          uiOutput("outCoordinates")
  #          )
  #        ),
  #      listActionButton=list( 
  #        actionLink("importData_spatial","",icon=icon("plus-circle")),
  #        actionLink("importData_table","",icon=icon("minus-circle"))
  #        )
  #
  #
  #      )
  #





  #
  # Populate column selection
  # 

  #    observe({
  #      mxCatch("Update input: layer columns",{
  #       # updateSelectInput(session, "selColumn",choices=mxReact$columnsInfo$column_name)
  #        cols = vtGetColumns(table=input$selLayer,port=3030,exclude=c("geom","gid"))
  #      })
  #    })


  #
  # populate column info reactive values, take reactivity on layer selection
  #
  #
  #    observe({
  #      mxCatch("Update mxReact: get layer columns",{
  #        mxReact$columnsInfo <- vtGetColumns(table=input$selLayer,port=3030,exclude=c("geom","gid"))
  #      })
  #    })
  #
  #
  #
  #    observe({
  #    print(input$leafletvtClickCoord)
  #    print(input$leafletvtClickProp)
  #    })





  #
  # update legends and colors
  #

  #    observe({
  #  
  #
  #      if(FALSE){
  #
  #      # addProviderTiles(baseLayer,group=grp)%>%
  #      dCol <- mxReact$col
  #      dPal <- mxReact$pal
  #      dVal <- mxReact$val 
  #
  #      vCol <- as.list(dCol)
  #      names(vCol) <- dVal
  #
  #      baseLayer <- input$selectBaseMap
  #
  #      grp = "grp_001"
  #
  #      if(!noDataCheck(dCol) && !noDataCheck(dVal) && !noDataCheck(baseLayer)){
  #        mxCatch("Add vector tiles and zoom",{
  #          proxyMap <- leafletProxy("mapxMap")
  #          #ext<-dbGetLayerExtent(dbInfo=dbInfo,table=input$selLayer)  
  #          centro<-dbGetLayerCentroid(dbInfo=dbInfo,table=input$selLayer)  
  #          if(noDataCheck(centro))return()
  #          proxyMap %>%
  #          clearGroup(grp) %>%
  #          addTiles('http://localhost:3030/services/tiles/afg_labels/{z}/{x}/{y}.png')%>%
  #          addVectorTiles(
  #            url="localhost",
  #            port=3030,
  #            table=input$selLayer,
  #            dataColumn=input$selColumn,
  #            group = grp
  #            )%>%
  #          addLegend(position="bottomright",pal=dPal,values=dVal,title=input$selLayer,layerId = "legends")%>%
  #          setView(lng=centro$lng, centro$lat, isolate(input$sliderZoom))
  #      })
  #      }
  #      }
  #
  # 
  #    })
  #

  # set opacity
  #    observe({
  #      opacity=input$selOpacity
  #      if(!noDataCheck(opacity)){ 
  #        setLayerOpacity(opacity=opacity)
  #      }
  #    })
  #
  #    observe({
  #      mapZoom <- input$mapxMap_zoom
  #      if(!noDataCheck(mapZoom))
  #        updateSliderInput(session=session,"sliderZoom",value=mapZoom) 
  #        return(NULL)
  #    })
  #
  #    observe({
  #      sliderZoom <- input$sliderZoom
  #      if(!noDataCheck(sliderZoom)){
  #          proxyMap <- leafletProxy("mapxMap")
  #          proxyMap %>%
  #          setZoom(sliderZoom)
  #      }
  #    })
  #

 # observe({
 #   createLayerSelect = list(
 #     tiles    = if(!noDataCheck(input$selLayer))input$selLayer,
 #     variable = if(!noDataCheck(input$selColumn))input$selColumn,
 #     palette  = if(!noDataCheck(input$selPalette))input$selPalette,
 #     opacity  = if(!noDataCheck(input$selOpacity))input$selOpacity,
 #     size     = if(!noDataCheck(input$selSize))input$selSize,
 #     basemap  = if(!noDataCheck(input$selectBaseMap))input$selectBaseMap
 #     )
 #   isolate({
 #   mxReact$createLayerSelect = list()
 #   if(any(sapply(createLayerSelect,is.null))) return() 
 #    mxDebugMsg("Set layer select")
 #     mxReact$createLayerSelect <- createLayerSelect
 #   })
 # })

  #
  # Merge all infos in one list
  #
#
#  observe({
#    l1 = mxReact$createLayerSelect
#    l2 = mxReact$createLayerSummary
#  
#    grp = "G1"
#    isolate({
#      if(!noDataCheck(l1) && !noDataCheck(l2)){
#        if(!any(sapply(l1,is.null)) && !any(sapply(l2,is.null))){
#          # http://stackoverflow.com/questions/18538977/combine-merge-lists-by-elements-names
#          l <- list(l1, l2)
#          keys <- unique(unlist(lapply(l, names)))
#          mxReact$vtLayers[[grp]] <- setNames(do.call(mapply, c(FUN=c, lapply(l, `[`, keys))), keys)
#          mxDebugMsg("Update vt layer")
#        }
#      }
#    })
#  })
#
#  #
#  # Add vector tiles
#  #
#
#  observe({ 
#    grp <- mxReact$grp
#    lay <- mxReact$vtLayers[[grp]][["tiles"]]
#    
#    vtStatus <- isolate(input$leafletvtStatus)
#    
#    redraw <- !isTRUE(paste0(lay,'_geom') == vtStatus$lay)
#
#    zm  <- 8
#
#    if(!noDataCheck(lay) && redraw){
#      vars <- vtGetColumns(table=lay,port=3030)$column_name
#      if(!noDataCheck(vars)){
#        centro<-dbGetLayerCentroid(dbInfo=dbInfo,table=lay)
#        if(noDataCheck(centro)){
#          centro <- list(lng=0,lat=0)
#          zm  = 1
#        }
#        proxyMap <- leafletProxy("mapxMap")
#        proxyMap %>%
#        clearGroup(grp) %>%
#        addVectorTiles(
#          url="localhost",
#          port=3030,
#          geomColumn="geom", # should be auto resolved by PGRestAPI
#          idColumn="gid", # should be auto resolved by PGRrestAPI
#          table=lay,
#          dataColumn=vars,
#          group = grp
#          ) %>%
#        setView(lng=centro$lng, centro$lat, zm)
#        mxDebugMsg("New layer on map")
#      }
#    }
#  })
#

# #
#  #  Set layer colors
#  #
#
#  observe({
#    grp <- mxStyle$group
#
#    layerInfo <-  mxReact$vtLayers[[grp]]
#    #  
#    #    selPalette <- input$selPalette
#    #    selSize <- input$selSize
#    #    selOpacity <- input$selOpacity
#
#
#    selPalette <- layerInfo[["palette"]]
#    selSize <- layerInfo[["size"]]
#    selOpacity <- layerInfo[["opacity"]]
#
#
#    paletteOk <- selPalette %in% layerInfo$paletteChoice
#
#
#    isolate({
#
#      if(!noDataCheck(layerInfo) && !noDataCheck(selPalette) && !noDataCheck(selSize) && !noDataCheck(selOpacity) && paletteOk){
#
#        # mxCatch("Set layer palettes",{
#
#        if(layerInfo$scaleType=="continuous") { 
#          pal <- colorNumeric(
#            palette = selPalette,
#            domain = layerInfo$dValues
#            )
#        }else{
#          pal <- colorFactor(
#            hsv(runif(layerInfo$nDistinct),1,(runif(layerInfo$nDistinct)+1)/2,0.8),
#            layerInfo$dValues
#            )
#        }
#
#
#
#
#        layerStyle <-  list(
#          col = pal(layerInfo$dValues),
#          pal = pal,
#          val = layerInfo$dValues,
#          lay = layerInfo$table,
#          var = layerInfo$column,
#          opa = selOpacity,
#          sze = selSize
#          )
#
#        #})
#
#        if(noDataCheck(mxReact$layersStyle)){
#          mxReact$layersStyle <- list()
#        }
#
#        mxReact$layersStyle[[grp]] <- layerStyle
#
#      }else{
#        return()
#      }
#    })
#  })
#
#
#
#
