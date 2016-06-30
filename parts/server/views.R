#                             
#  _ __ ___   __ _ _ __   __  __
# | '_ ` _ \ / _` | '_ \  \ \/ /
# | | | | | | (_| | |_) |  >  < 
# |_| |_| |_|\__,_| .__/  /_/\_\
#                 | |           
#                 |_|           
# views list generator



#
# VIEW LIST
#

observe({
  mxTimer("start", "View list : fetch from db")
  country <- reactProject$name
  update <- reactMap$viewsDataListUpdate


  userId <- mxGetListValue(reactUser$data,"id")
  canRead <- mxGetListValue(reactUser$role,c("desc","read"))
  hasNoValue  <- any(sapply(c(country,userId,canRead),noDataCheck))


  mxCatch(title="Populate views from db",{ 
    if(hasNoValue) stop("Error when validaing views input: some input are emtpy")
    reactMap$viewsData <- mxMakeViewList(
      country    = country,
      userId     = userId,
      visibility = canRead
      )
    reactMap$viewsDataToDisplay <-  list()
})
  mxTimer("stop")
})



#
# VIEWS LIST TO HTML
#
output$checkInputViewsContainer <- renderUI({
  mxTimer("start", "View list : create ui")
  viewsUi <- mxMakeViews_cache(reactMap$viewsData)
  mxTimer("stop")
  return(viewsUi)
})


#
# OBSERVE META DATA REQUEST
#

observeEvent(input$mxRequestMeta,{
  mxCatch(title="Get view meta data",{
  # get the view id
  vId <- input$mxRequestMeta$id 
  #
  # here we want to display the description of the view
  # and the meta data from the layer. 
  # could be anything, but for showcasing, it will do
  # the trick. We can also imagine single request with a join
  # 
  # Get view data. Could be any column. We only keep the first result
  viewData <- mxGetViewData(vId,c("style","layer"))[[1]]
  # get the view description
  viewDesc <- viewData$style$description
  # get layer meta data
  layerMeta <- mxGetLayerMeta(viewData$layer)
  # merge
  layerMeta$`View description` <- viewDesc
  # convert te layer meta to an html list

    ui <-div(class="mx-panel-400",
       HTML(
         listToHtmlClass(
           layerMeta
           )
         )
       )

  panModal <- mxPanel(
    id="panMetaModal",
    title=sprintf("Metadata"),
    subtitle="Information available",
    html=ui
    )

  mxUpdateText(id="panelAlert",ui=panModal)

})
})



#
# handle company filter
#
observe({
  mxCatch(title="Company filter",{
    f<-input$filterLayer
    if(!noDataCheck(f)){

      ext <- mxDbGetFilterCenter(
        table=f$layer,
        column=f$column,
        value=f$value,
        operator="="
        )

      proxyMap <- leafletProxy("mapxMap")

      
      proxyMap %>% fitBounds(
        lng1=ext$lng1,
        lng2=ext$lng2,
        lat1=ext$lat1,
        lat2=ext$lat2
        )

    }
})
})



#
# VIEWS MANAGER
#




observe({
  storyView <- input$storyMapData
  #        if(!noDataCheck(storyView$view)){
  #          reactMap$viewsDataFromStory <- storyView$view
  #        }
  #
  if(!noDataCheck(storyView$extent)){
    ext <- storyView$extent

    proxyMap <- leafletProxy("mapxMap")
    proxyMap %>% setView(
      lng=ext[[1]],
      lat=ext[[2]],
      zoom=ext[[3]]
      )
  }

})



observe({
  mxCatch(title="Views manager",{

    if(reactUi$panelMode %in% c("mapViewsExplorer","mapStoryReader")){
      #
      # views from url
      #
      vUrl <- reactMap$viewsDataFromUrl
      #
      # views from menu and story
      #
      vMenu <- unique(c(
        input$viewsFromMenu,
        input$viewsFromPreview
        ))
      mxDebugMsg(vMenu)
      #
      # Views available
      #
      vAvailable <- names(reactMap$viewsData) 
      #
      # Reset view to display
      #
      vToDisplay <- ""

      #
      # Build list
      #

      if(noDataCheck(vMenu) && !noDataCheck(vUrl)){
        vToDisplay <- vUrl[vUrl %in% vAvailable]
      }else if(!noDataCheck(vMenu)){
        vToDisplay <-  vMenu[vMenu %in% vAvailable]
      }else{
        vToDisplay <- mxConfig$noData
      }

      reactMap$viewsDataToDisplay <- vToDisplay
      reactMap$viewsDataFromUrl <- ""

    }
      })
})




# views queuing system
observeEvent(reactMap$viewsDataToDisplay,{
  mxCatch(title="Views queing system",{
    mxDebugMsg(
      paste("View to display =",
        reactMap$viewsDataToDisplay
        )
      )
    # available views data
    vAll <- names(reactMap$viewsData)
    # views list to render
    vToDisplay <- reactMap$viewsDataToDisplay
    # views actually rendered by leaflet
    vDisplayed <- input$mapxMap_groups
    # views saved in leafletvt object
    vProcessed <- input$leafletvtViews
    # names of all views
    # render only available ones for the user.
    vDisplayed <- vDisplayed[vDisplayed %in% vAll]
    # views to hide
    reactMap$viewsToHide <- unique(vDisplayed[! vDisplayed %in% vToDisplay])
    # views to reactivate
    vToShow <- vToDisplay[vToDisplay %in% vProcessed]
    reactMap$viewsToReveal <- unique(vToShow[!vToShow %in% vDisplayed])
    # views to download and display
    reactMap$viewsToMake <-  unique(vToDisplay[!vToDisplay %in% vProcessed][1])
      })
})



observeEvent(reactProject$name,{
  vToRemove = c(
    reactMap$viewsToMake,
    reactMap$viewsToReveal,
    reactMap$viewsDataToDisplay
    )

  vToRemove<-vToRemove[ !vToRemove %in% mxConfig$noData ]

 proxyMap <- leafletProxy("mapxMap")

    proxyMap  %>% clearControls() 

  if(length(vToRemove)==0) return()
  
      for(v in vToRemove){ 

        proxyMap %>%
      clearGroup(as.character(v))
  }
})








# Views to hide
observeEvent(reactMap$viewsToHide,{
  mxCatch(title="View to hide",{
    vToHide <- reactMap$viewsToHide
    if(!noDataCheck(vToHide)){
      for(vth in vToHide){
        mxDebugMsg(
          paste("View to hide =",
            vth
            )
          )
        # set expected legend id
        legendId <- sprintf("%s_legends",vth)
        #mxRemoveEl(class=legendId)
        # get map proxy, hide group and control. 
        proxyMap <- leafletProxy("mapxMap")
        proxyMap %>% 
        removeControl(layerId=legendId) %>%
        hideGroup(as.character(vth))
        # double removal
      }
    }
      })
})


# Views to display but not already processed.
# Use 
observeEvent(reactMap$viewsToMake,{
  mxCatch(title="Views to calc",{
   
    vToCalc <- reactMap$viewsToMake
    vToCalc <- vToCalc[!sapply(vToCalc,noDataCheck)]
    vData <- reactMap$viewsData

    if(length(vToCalc)>0){
      for(vtc in vToCalc){

        sty <- vData[[vtc]]$style

        if(!noDataCheck(sty)){
          mxDebugMsg(paste("First style computation for",vtc))
          reactStyle$layer <- sty$layer
          reactStyle$group <- vtc
          reactStyle$variable <- sty$variable

          # variable to keep
          vToKeep <- sty$variableToKeep 
          if(is.null(vToKeep))vToKeep <- mxConfig$noVariable
          reactStyle$variableToKeep <- vToKeep

          # variable unit
          vUnit <- sty$variableUnit
          if(is.null(vUnit))vUnit <- ""
          reactStyle$variableUnit <- vUnit

        }
      }
    }
      })
})

# Views to reactivate
observeEvent(reactMap$viewsToReveal,{
  mxCatch(title="Views to reactivate",{
    vToShow <- reactMap$viewsToReveal
    vData <- reactMap$viewsData
    if(!noDataCheck(vToShow)){

      proxyMap <- leafletProxy("mapxMap")

      for(vId in vToShow){

        legendId <- sprintf("%s_legends",vId)
        legendClass <- sprintf("info legend %s",legendId)

        sty <- vData[[vId]]$style

        hasLegend <- ! isTRUE(sty$hideLegends)

        # compute legend if necessary
        if(hasLegend){
          tit <- sty$title
          pal <- sty$palette
          val <- sty$values

          sty <- addPaletteFun_cache(sty,pal)
          palFun <- sty$paletteFun
          proxyMap %>%
          showGroup(as.character(vToShow)) %>%
          addLegend(
            position="bottomright",
            layerId=legendId,
            class=legendClass,
            pal=palFun,
            values=val,
            title=tit
            )
        }else{
          proxyMap %>%
          showGroup(as.character(vToShow))
        }

      }
    }

      })
})

