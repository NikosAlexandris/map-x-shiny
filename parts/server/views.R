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
  cntry <- mxReact$selectCountry
  update <- mxReact$viewsListUpdate
  mxCatch(title="Populate views from db",{ 
    start <- Sys.time()
    mxReact$views <- mxMakeViewList(dbInfo,cntry)
    mxDebugMsg(paste("Time for generating views list=",Sys.time()-start))
})
})



#
# VIEWS LIST TO HTML
#
output$checkInputViewsContainer <- renderUI({
  start <- Sys.time()
  viewsUi <- mxMakeViews_cache(mxReact$views,mxConfig$class)
  mxDebugMsg(paste("Time for generating views ui=",Sys.time()-start))
  return(viewsUi)
})


#
# OBSERVE META DATA REQUEST
#

observeEvent(input$mxRequestMeta,{

  layerName <- input$mxRequestMeta 
  meta <- mxGetLayerMeta(dbInfo,layerName)
  meta <- HTML(listToHtmlClass(meta))
  panModal <- mxPanel(
    id="panMetaModal",
    title=sprintf("Metadata"),
    subtitle=sprintf("Information available for the layer %s ",layerName),
    html=meta
    )

  mxUpdateText(id="panelAlert",ui=panModal)


})



#
# handle company filter
#
observe({
  f<-input$filterLayer
  if(!noDataCheck(f) && ! isTRUE(f == mxConfig$noFilter)){
    ext <- dbGetFilterCenter(
      dbInfo=dbInfo,
      table=f$layer,
      column=f$column,
      value=f$value,
      operator="="
      )
    proxyMap <- leafletProxy("mapxMap")

    proxyMap %>% fitBounds(
      lng1=min(ext[c("lng1","lng2")])-0.3,
      lat1=min(ext[c("lat1","lat2")])-0.3,
      lng2=max(ext[c("lng1","lng2")])+0.3,
      lat2=max(ext[c("lat1","lat2")])+0.3
      )   
  }

})



#
# VIEWS MANAGER
#




observe({
  storyView <- input$storyMapData
  #        if(!noDataCheck(storyView$view)){
  #          mxReact$viewsFromStory <- storyView$view
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
    #
    # views from url
    #
    vUrl <- mxReact$viewsFromUrl
    #
    # views from menu and story
    #
    vMenu <- c(
      input$viewsFromMenu
      )
    #
    # Views available
    #
    vAvailable <- names(mxReact$views) 
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

    mxReact$viewsToDisplay <- vToDisplay
    mxReact$viewsFromUrl <- ""

      })
})




# views queuing system
observeEvent(mxReact$viewsToDisplay,{
  mxCatch(title="Views queing system",{
    mxDebugMsg(
      paste("View to display =",
        mxReact$viewsToDisplay
        )
      )
    # available views data
    vAll <- names(mxReact$views)
    # views list to render
    vToDisplay <- mxReact$viewsToDisplay
    # views actually rendered by leaflet
    vDisplayed <- input$mapxMap_groups
    # views saved in leafletvt object
    vProcessed <- input$leafletvtViews
    # names of all views
    # render only available ones for the user.
    vDisplayed <- vDisplayed[vDisplayed %in% vAll]
    # views to hide
    mxReact$vToHide <- unique(vDisplayed[! vDisplayed %in% vToDisplay])
    # views to reactivate
    vToShow <- vToDisplay[vToDisplay %in% vProcessed]
    mxReact$vToShow <- unique(vToShow[!vToShow %in% vDisplayed])
    # views to download and display
    mxReact$vToCalc <-  unique(vToDisplay[!vToDisplay %in% vProcessed][1])
      })
})


# Views to hide
observeEvent(mxReact$vToHide,{
  mxCatch(title="View to hide",{
    vToHide <- mxReact$vToHide
    if(!noDataCheck(vToHide)){
      # set expected legend id
      legendId <- sprintf("%s_legends",vToHide)
      # get map proxy, hide group and control. 
      proxyMap <- leafletProxy("mapxMap",deferUntilFlush=FALSE)
      proxyMap %>% 
      removeControl(layerId=legendId) %>%
      hideGroup(as.character(vToHide))
      # double removal
      mxRemoveEl(class=legendId)
    }
      })
})


# Views to display but not already processed.
# Use 
observeEvent(mxReact$vToCalc,{
  mxCatch(title="Views to calc",{
    vToCalc <- mxReact$vToCalc
    vData <- mxReact$views
    if(!noDataCheck(vToCalc)){
      sty <- vData[[vToCalc]]$style
      if(!noDataCheck(sty)){
        mxDebugMsg(paste("First style computation for",vToCalc))
        mxStyle$layer <- sty$layer
        mxStyle$group <- vToCalc
        mxStyle$variable <- sty$variable
        vUnit <- sty$variableUnit
        vToKeep <- sty$variableToKeep 
        # As we check for null in layerStyle(),add "noData/noVariable" values.
        if(is.null(vToKeep))vToKeep <- mxConfig$noVariable
        mxStyle$variableToKeep <- vToKeep

        if(is.null(vUnit))vUnit <- ""
        mxStyle$variableUnit

      }
    }
      })
})

# Views to reactivate
observeEvent(mxReact$vToShow,{
  mxCatch(title="Views to reactivate",{
    vToShow <- mxReact$vToShow
    vData <- mxReact$views
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

