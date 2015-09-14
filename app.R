
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
  # New view
  #

  source("parts/server/creator.R",local=T)



  #
  # URL parsing
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
  # POPULATE VIEWS LIST TODO: add filter on desc,title,class,....
  #

  observe({
    mxCatch(title="Populate views from db",{
      cntry <- mxReact$selectCountry
      update <- mxReact$viewsListUpdate
      views = list()
      if(!noDataCheck(cntry)){
        viewsDf <- mxGetViewsList(dbInfo,mxConfig$viewsListTableName,country=cntry)
        if(isTRUE(nrow(viewsDf)>0)){
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
  # VIEWS LIST TO HTML
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
  # VIEWS MANAGER
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
        #if(!is.null(vToDisplay)){ 
          mxReact$viewsToDisplay <- vToDisplay
          mxReact$viewsFromUrl=NULL
        #}
      }
    })
  })



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


      #
      # VIEWS TO COMPUTE
      #

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


      #
      # VIEWS TO REACTIVATE
      #

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


      #
      # VIEWS TO HIDE
      #


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
          if(mxReact$mapPanelMode=="mapViewsStory"){
            mxStyle$basemap <- sty$basemap
          }else{
          mxStyle$basemap <- mxConfig$noLayer
          }
          mxStyle$size <- sty$size
          mxStyle$hideLabels <- sty$hideLabels
          mxStyle$hideLegends <- sty$hideLegends
        }
      }
    })
  })


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
  # MANAGE PANEL MODE
  #

  source('parts/server/panelMode.R',local=T)



  #
  # CLEAR LAYER AFTER CREATOR MODE EXIT
  #

  observeEvent(input$btnViewsExplorer,{
    mxCatch(title="Clean creator layers",{
    dGroup <- mxConfig$defaultGroup
    legendId <- paste(dGroup,"_legends")
    proxyMap <- leafletProxy("mapxMap")
    proxyMap %>%
    clearGroup(dGroup) %>% 
    removeControl(legendId) 
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
            group=group,
            options=list(
              'zIndex'=0
              )
            )%>% setView(center$lng,center$lat,center$zoom)
        } 
        )
    }
  })





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
        mxDebugMsg(paste("Ready to add vector tiles",lay," in group",grp))
        isolate({
          if(mapViewMode == "mapViewsCreator"){
            vars <- vtGetColumns(table=lay,port=3030)$column_name
            grpClean <- mxConfig$defaultGroup
          }else{
            vars <- c(mxStyle$variable)
            grpClean <- NULL
          }
        })
        if(!noDataCheck(vars)){
          proxyMap <- leafletProxy("mapxMap")
          proxyMap %>%
          {if(!noDataCheck(grpClean)) clearGroup(.,group=grpClean) else . } %>%
          addVectorTiles(
            url="localhost",
            port=3030,
            geomColumn="geom", # should be auto resolved by PGRestAPI
            idColumn="gid", # should be auto resolved by PGRrestAPI
            table=lay,
            dataColumn=vars,
            group = grp
            )  

          mxDebugMsg(paste("Start downloading",lay))
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
      #if(mxReact$mapPanelMode=="mapViewsStory"){
        layId = "basemap"
        selBaseMap <- mxStyle$basemap 
        selBaseMapGlobal <- input$selectConfigBaseMap
        if(!selBaseMapGlobal == mxConfig$noLayer ) selBaseMap = selBaseMapGlobal
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
            addProviderTiles(selBaseMap,layerId=layId,options=list('zIndex'=0))
          }else{
            proxyMap %>%
            removeTiles(layId) %>%
            addTiles(
              "https://api.mapbox.com/v4/mapbox.satellite/{z}/{x}/{y}.png?access_token=pk.eyJ1IjoiaGVsc2lua2kiLCJhIjoiMjgzYWM4NTE0YzQyZGExMTgzYTJmNGIxYmEwYTQwY2QifQ.dtq8cyvJFrJSUmSPtB6Q7A"
              ,layerId=layId,options=list('zIndex'=0))
          }
        }
   #   }
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

  # mode explorer
  observeEvent(input$leafletvtStatus,{
    mxCatch(title="Update layer style, explorer mode",{
      if(isTRUE(mxReact$mapPanelMode=="mapViewsExplorer")){
        sty <- layerStyle() 
        sta <- input$leafletvtStatus 
        mxSetStyle(style=sty,status=sta)
      }
        })
  })

  # mode creator
 observe({
   mxCatch(title="Update style, creator mode",{
      if(isTRUE(mxReact$mapPanelMode=="mapViewsCreator")){
        sta <- input$leafletvtStatus
        sty <- layerStyle()
        mxSetStyle(style=sty,status=sta)
      }
        })
  })

} # end of server object


mxCatch(title="Main application",{
  shinyApp(ui, server)
})

