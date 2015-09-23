

# MAP SECTION 
#
    observe({
      mxUiEnable(id="sectionMap",enable=mxReact$allowMap) 
    })

    observe({
      mxUiEnable(id="btnViewsCreator",enable=mxReact$allowViewsCreator) 
    })
observe({
  if(mxReact$allowMap){
    
    source('parts/server/upload.R',local=TRUE)
    source("parts/server/creator.R",local=T)



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
              title <- v[[i]]$title 
              class <- v[[i]]$class
              className <- cl[cl$id == class,'n']
              viewId <- as.list(i)
              names(viewId) <- title
              other <- viewsList[[className]]
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
        vUrl <- mxReact$viewsFromUrl
        vMenu <- input$viewsFromMenu
        vAvailable <- names(mxReact$views) 
        vToDisplay <- NULL
        if(!noDataCheck(vAvailable)){  
          if(noDataCheck(vMenu) && !noDataCheck(vUrl)){
            vToDisplay <- vUrl[vUrl %in% vAvailable]
          }else if(!noDataCheck(vMenu)){
            vToDisplay <-  vMenu[vMenu %in% vAvailable]
          }else{
            vToDisplay <- mxConfig$noData
          }
          mxReact$viewsToDisplay <- vToDisplay
          mxReact$viewsFromUrl <- NULL
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

              sty <- addPaletteFun(sty,pal)
              palFun <- sty$paletteFun

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
          mxStyle <- reactiveValues()

          dGroup <- mxConfig$defaultGroup
          legendId <- paste0(dGroup,"_legends")
          proxyMap <- leafletProxy("mapxMap")
          proxyMap %>%
          #hideGroup(dGroup) %>% 
          clearGroup(dGroup) %>% 
          removeControl(legendId) 
})
    })

    #
    # CLEAR LAYER AFTER CREATOR MODE
    #


    observeEvent(input$btnViewsCreator,{
      mxCatch(title="Clean explorer layers",{
        mxStyle <- reactiveValues()

          mxReact$viewsToDisplay = ""


})
    })

    #
    # MAIN MAP
    #

    output$mapxMap <- renderLeaflet({
        if(noDataCheck(mxReact$selectCountry))return()
        mxDebugMsg("DISPLAY MAIN MAP")
        group = "main"
        iso3 <- mxReact$selectCountry
        if(!noDataCheck(iso3)){
          center <- mxConfig$countryCenter[[iso3]] 
          mxConfig$baseLayerByCountry(iso3,group,center)
        }
    })

    #
    # if previous mode was creator, group is not properly 
    #




    #
    # Add vector tiles
    #

    observe({ 
       # mxCatch(title="Add vector tiles",{
          grp <- mxStyle$group
          lay <- mxStyle$layer

          mapViewMode <- isolate(mxReact$mapPanelMode) 
          if(is.null(mapViewMode))mapViewMode="mapViewsExplorer" # TODO: set default for mxReact$mapPanelMode 
          if(!noDataCheck(lay)){
            mxDebugMsg(paste("Ready to add vector tiles",lay," in group",grp))
            isolate({
              if(mapViewMode == "mapViewsCreator"){
                vars <- vtGetColumns(table=lay,port=mxConfig$portVt)$column_name
                #grpClean <- mxConfig$defaultGroup
              }else{
                vars <- c(mxStyle$variable)
               # grpClean <- NULL
              }
            })
            if(!noDataCheck(vars)){
              proxyMap <- leafletProxy("mapxMap")
              proxyMap %>%
              clearGroup(mxConfig$defaultGroup)

              proxyMap %>%
              addVectorTiles(
                url=mxConfig$hostVt,
                port=3030,
                geomColumn="geom", # should be auto resolved by PGRestAPI
                idColumn="gid", # should be auto resolved by PGRrestAPI
                table=lay,
                dataColumn=vars,
                group = grp
                )  
              mxDebugMsg(paste("Start downloading",lay,"from host",mxConfig$hostVt,"on port:",mxConfig$portVt))
            }
          }
#})
    })



 #   observeEvent(input$leafletvtStatus,{
 #     sta = input$leafletvtStatus 
 #   })

    #
    # Set map center based on center of layer
    #


    observeEvent(input$btnZoomToLayer,{
        if(noDataCheck(mxReact$selectCountry))return()
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

          if(isTRUE(!selBaseMapGlobal == mxConfig$noLayer)) selBaseMap = selBaseMapGlobal
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
        if(noDataCheck(mxReact$selectCountry))return()
        mxCatch(title="Set layer labels",{
          group = "labels"
          hideLabels <- mxStyle$hideLabels
          iso3 <- mxReact$selectCountry
          if(!noDataCheck(hideLabels) && !noDataCheck(iso3)){
            proxyMap <- leafletProxy("mapxMap")
            if(!hideLabels){
              mxConfig$labelLayerByCountry(iso3,group,proxyMap) 
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
      mxCatch(title="Set layerStyle()",{
        # check if vector tiles are loaded 
        # and if they correspond to mxStyle
        grpLocal <- mxStyle$group
        layLocal <- mxStyle$layer
        grpClient <- input$leafletvtStatus$grp
        layClient <- input$leafletvtStatus$lay
        if(
          !noDataCheck(grpLocal) && 
          !noDataCheck(grpClient) && 
          !noDataCheck(layLocal) && 
          !noDataCheck(layClient)
          ){
          if(
            grpClient == grpLocal && 
            layClient == sprintf("%s_%s",layLocal,mxConfig$defaultGeomCol)
            ){
            sty <- reactiveValuesToList(mxStyle)
            if(!any(sapply(sty,noDataCheck))){
              palOk <- isTRUE(sty$palette %in% sty$paletteChoice)
              if(palOk){ 
                sty <- addPaletteFun(sty,sty$palette)
                sty$colors <- sty$paletteFun(sty$values)
                return(sty)
              }
            }
          }
        }
        return(NULL)
})
    })


    observe({
      sty = layerStyle()
      if(!noDataCheck(sty)){
      mxDebugMsg(paste("layerStyle() received for",sty$group))
      mxSetStyle(style=sty)
      }
    })

#
#
#    # 
#    # Update layer color and legend
#    # 
#
#    # mode explorer
#    observeEvent(input$leafletvtStatus,{
#        mxCatch(title="Update layer style, explorer mode",{
#          if(isTRUE(mxReact$mapPanelMode=="mapViewsExplorer")){
#            sty <- layerStyle() 
#            mxSetStyle(style=sty,status=sta)
#          }
#})
#    })
#
#    # mode creator
#    observe({
#      if(mxReact$allowViewsCreator){
#        mxCatch(title="Update style, creator mode",{
#          if(isTRUE(mxReact$mapPanelMode=="mapViewsCreator")){
#            sty <- layerStyle()
#            sta <- input$leafletvtStatus
#          mxDebugMsg(paste("mxSetStyle in observer requested for ",sty$group))
#            mxSetStyle(style=sty,status=sta)
#          }
#})
#      }
#    })
#


  }

})
