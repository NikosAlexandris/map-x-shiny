
#
# POPULATE VIEWS LIST 
#

observe({
  mxCatch(title="Populate views from db",{
    cntry <- mxReact$selectCountry
    update <- mxReact$viewsListUpdate
    views = list()
    if(!noDataCheck(cntry)){
      viewsDf <- mxGetViewsTable(dbInfo,mxConfig$viewsListTableName,country=cntry)
      if(isTRUE(nrow(viewsDf)>0)){
        # create list of map views
        for(i in viewsDf$id){
          views[[i]] <- as.list(viewsDf[viewsDf$id==i,])
          views[[i]]$style <- fromJSON(views[[i]]$style)
        }
      }
      mxReact$views <- views
    }
})
})


#
# VIEWS LIST TO HTML
#
observe({
  start = Sys.time()
  # mxCatch(title="HTML views construction",{
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
        #
        # set item id text
        #
        it <- items[j]
        itId <- as.character(it)
        itIdCheckOption <- sprintf('checkbox_opt_%s',itId)
        itIdLabel <- sprintf('label_for_%s',itId)
        itIdCheckOptionLabel <- sprintf('checkbox_opt_label_%s',itId)
        itIdCheckOptionPanel <- sprintf('checkbox_opt_panel_%s',itId)
        itIdFilterCompany <- sprintf('select_filter_for_%s',itId)
        #
        # check if time slider or filter should be shown
        #
        hasDate <- isTRUE(v[[itId]]$style$hasDateColumns)
        hasCompany <- isTRUE(v[[itId]]$style$hasCompanyColumn)
        #
        # create time slider
        #
        if(hasDate){
          timeSlider <- mxTimeSlider(
            id=itId,
            min=as.numeric(as.POSIXct(v[[itId]]$dateVariableMin))*1000,
            max=as.numeric(as.POSIXct(v[[itId]]$dateVariableMax))*1000,
            lay=v[[itId]]$layer
            )
        }else{
          timeSlider <- tags$div()
        }
        # 
        # create custom selectize input for company
        #
        if(hasCompany){
          # which field contains company names ?
          fieldSelected <- "parties"
          # get distinct company names for this layer
          q <- sprintf(
            "SELECT array_to_json(array_agg(row_to_json(t))) 
            FROM ( SELECT DISTINCT(%1$s) 
              FROM  %2$s 
              ORDER BY %1$s) t",
            fieldSelected,
            v[[itId]]$layer
            )
          companies <- as.character(mxDbGetQuery(dbInfo,q))
          # create selectize js code
          filterSelect <- tagList(
            tags$div(id=itIdFilterCompany,placeholder=sprintf("Search for '%s' ...",fieldSelected)),
            tags$script(
              sprintf(" $('#%1$s').selectize({
                maxItems:null,
                onChange: function(value){
                  mxSetFilter('%2$s','%3$s','%4$s',value)
                },
                valueField: '%4$s',
                labelField: '%4$s',
                searchField: '%4$s',
                options:%5$s,
                plugins: ['remove_button']
        })",
              itIdFilterCompany,#1
              v[[itId]]$layer,#2
              itId,#3
              fieldSelected,#4
              companies#5
              )
            )
          )
      }else{
        filterSelect <- tags$div()
      }
      # toggle option panel for this view
      toggleOptions <- sprintf("toggleOptions('%s','%s','%s')",itId,itIdCheckOptionLabel,itIdCheckOptionPanel)
      # set on hover previre for this view
      previewTimeOut <- tags$script(sprintf("vtPreviewHandler('%1$s','%2$s','%3$s')",itIdLabel,itId,500))
      # create html
      val <- div(class="checkbox",
        tags$label(id=itIdLabel,
          #onmouseover=sprintf("vtPreview('%s')",itId),
          #onmouseout=sprintf("vtPreview('%s')",""),
          tags$input(type="checkbox",class="vis-hidden",name=id,value=itId,
            onChange=toggleOptions),
          div(class="map-views-item",
            tags$span(class="map-views-selector",names(it)),
            mxCheckboxIcon(itIdCheckOption,itIdCheckOptionLabel,"cog",display=FALSE)
            ) 
          ),
        conditionalPanel(sprintf("isCheckedId('%s')",itIdCheckOption),
          tags$div(class="map-views-item-options",id=itIdCheckOptionPanel,
            mxSliderOpacity(itId,v[[itId]]$style$opacity),
            timeSlider,
            filterSelect
            )
          ),
        previewTimeOut
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
  mxDebugMsg(paste("Time for generating views list=",Sys.time()-start))
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
                lng1=min(ext[c('lng1','lng2')])-0.3,
                lat1=min(ext[c('lat1','lat2')])-0.3,
                lng2=max(ext[c('lng1','lng2')])+0.3,
                lat2=max(ext[c('lat1','lat2')])+0.3
                )   
            }

          })



          #
          # VIEWS MANAGER
          #

          observe({
            mxCatch(title="Views manager",{
              vUrl <- mxReact$viewsFromUrl
              vMenu <- c(input$viewsFromMenu,input$viewsFromPreview)
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




          # views queuing system
          observeEvent(mxReact$viewsToDisplay,{
            mxCatch(title="Views queing system",{
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
              mxReact$vToHide <- vDisplayed[! vDisplayed %in% vToDisplay]
              # views to reactivate
              vToShow <- vToDisplay[vToDisplay %in% vProcessed]
              mxReact$vToShow <- vToShow[!vToShow %in% vDisplayed]
              # views to download and display
              mxReact$vToCalc <-  vToDisplay[!vToDisplay %in% vProcessed][1]
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
                hideGroup(as.character(vToHide))

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
                  vToKeep <- sty$variableToKeep 

                  # As we check for null in layerStyle(),add "noData/noVariable" values.
                  if(is.null(vToKeep))vToKeep=mxConfig$noVariable
                  mxStyle$variableToKeep = vToKeep
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
                #legendId <- sprintf("%s_legends",vToShow)
                legendId <- sprintf("info legend %s_legends",vToShow)
                proxyMap <- leafletProxy("mapxMap")
                sty <- vData[[vToShow]]$style
                hasLegend <- ! isTRUE(sty$hideLegends)

                # compute legend if necessary
                if(hasLegend){
                  tit <- sty$title
                  pal <- sty$palette
                  val <- sty$values
                  sty <- addPaletteFun(sty,pal)
                  palFun <- sty$paletteFun
                  proxyMap %>%
                  showGroup(as.character(vToShow)) %>%
                  addLegend(position="topright",class=legendId,pal=palFun,values=val,title=tit)
                  #addLegend(position="topright",pal=palFun,values=val,title=tit,layerId = legendId)
                }else{
                  proxyMap %>%
                  showGroup(as.character(vToShow))
                }
              }

                })
          })

