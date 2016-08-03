#                             
#  _ __ ___   __ _ _ __   __  __
# | '_ ` _ \ / _` | '_ \  \ \/ /
# | | | | | | (_| | |_) |  >  < 
# |_| |_| |_|\__,_| .__/  /_/\_\
#                 | |           
#                 |_|           
# country section server

mxUiEnable(id="sectionCountry",enable=TRUE) 






#
# Country input selection : save in db is needed
#
observeEvent(input$selectCountry,{
  
  mxDebugMsg(sprintf("input$selectCountry received: %s",input$selectCountry ) )

  selCountry <- input$selectCountry

  if(!noDataCheck(selCountry) && reactUser$isLogged ){

    mxUiEnable(
      id="selectCountryPanel",
      enable=FALSE
      )
    # update reactive value and db if needed
    mxDbUpdateUserData(reactUser,
      path=c("user","cache","last_project"),
      value=selCountry
      )

    reactProject$name <- selCountry
  }
})


observeEvent(reactProject$name,{

  cSelect <- reactProject$name 

  if(!noDataCheck(cSelect)){
    mxConsoleText(cSelect)
    if(cSelect %in% names(mxData$countryStory)){
      cInfo  <- mxData$countryStory[[cSelect]]
      # extract country metrics
      countryMetrics <-  tags$ul(class="list-group",
        tags$li(
          class="list-group-item",
          tags$b("GDP :"),
          tags$span(class="badge",
            cInfo[['gdp']])
          ),
        tags$li(
          class="list-group-item",
          tags$b("HDI :"),
          tags$span(class="badge",
            cInfo[['hdi']]
            )
          ),
        tags$li(
          class="list-group-item",
          tags$b("Status EITI:"),
          tags$span(class="badge",
            cInfo[['eiti_status']]
            )
          ),
        tags$li(
          class="list-group-item",
          tags$b("Gvt. revenues:"),
          tags$span(class="badge",
            cInfo[['gvt_revenues']]
            )
          ),
        tags$li(
          class="list-group-item",
          tags$b("Comp. payments"),
          tags$span(class="badge",
            cInfo[['comp_payment']]
            )
          )
        )
      countryNarrative <-
        div(class="narratives-background",
          HTML(cInfo[['story']])
          )
    }else{
      countryMetrics <- tags$ul(class="list-group",tags$li(" No metrics available yet ... "))
      countryNarrative <- tags$ul(class="list-group",tags$li(" No narratives available yet ... "))
    }


    # set countryname with standard code
    countryName <- countrycode(cSelect,"iso3c","country.name")

    # update graphs
    if(! noDataCheck(cSelect)){
      dat = mxData$rgi_score_2013
      datCountry = dat[dat$iso3 == cSelect,]
      datComp = dat[dat$iso3 == "NOR",]
      rgiNames = names(datCountry)
      labels = rgiNames[
        ! rgiNames %in% c(
          'iso3','Rank','Country','Resource','measured','Resource measured'
          )
        ]
      values = as.vector(t(datCountry[labels]))
      valuesComp = as.vector(t(datComp[labels]))
      labels = strtrim(labels,4) 
      mxUpdateChartRadar(
        id='testChart',
        idLegend="testChartLegends",
        main=countryName,
        compMain="Norway",
        labels= labels,
        values=values,
        compValues=valuesComp
        ) 
    }

    # output ui and text
 
    cListChoice <- c(
      names(mxConfig$countryListChoices$potential),
      names(mxConfig$countryListChoices$pending)
      )

    names(cListChoice) <- c(
      as.character(mxConfig$countryListChoices$potential),
      as.character(mxConfig$countryListChoices$pending)
      )
    countryNameNav <- cListChoice[[toupper(cSelect)]]



    cL <- tags$div(
      class="visible-lg-inline",
      countryNameNav # full name
      )

    cM <- tags$div(
      class="visible-md-inline",
      countryName # short name
      )

    cS <- tags$div(
      class="visible-sm-inline visible-xs-inline",
      cSelect # iso 3 code
      )

    mxUpdateText(id="countryTitle",text=
      tagList(
        cL,cM,cS
        )
      )

    mxUpdateText(
      id="countryName",
      text=countryNameNav
      )

    mxUpdateText(
      id="countryMetrics",
      text=countryMetrics
      )
    mxUpdateText(
      id="countryNarrative",
      text=countryNarrative
      )
  }
})



#
# SHOW INDEX
#
observe({
  mxCatch("Plot WDI data",{
    idx <- input$selectIndicator
    cnt <- reactProject$name
    msg <- ""
    dat <- data.frame()

    if(!noDataCheck(idx) && !noDataCheck(cnt)){


      # Update message text
      mxUpdateText("wdiMsg",
        sprintf("Requested data for %1$s in %2$s"
          , idx
          , cnt
          )
        )
      # Try to connect to worldbang.org
      if(!mxCanReach("data.worldbank.org")){
        msg <- "No connection to worldbank development index."
        mxUpdateText("wdiMsg",msg)
      }else{
        tryCatch({
          dat <- WDI(
            indicator = idx, 
            country = countrycode(cnt,'iso3c','iso2c'), 
            start = 1980, 
            end = 2016
            )
        },
        error = function(cond){ 
          mxDebugToJs(
            sprint("WDI graph error in %1$s: %2$s"
              , cnt
              , cond$message
              )
            )
        },
        warning = function(cond){ 
          mxDebugToJs(
            sprintf("WDI graph Warning in %1$s:  %2$s"
              , cnt
              , cond$message
              )
            )
        })

        # If we have something, update dyGraph
        if(nrow(dat)>0){
          dat = na.omit(dat)

          dat$year <- as.Date(paste0(dat$year,'-12-31'))
          datSeries <- xts(dat[,idx],order.by=dat$year)
          idxName <- names(mxConfig$wdiIndicators[idx])

          graphIndicator <- dygraph(
            data=datSeries,
            main=idxName,
            ylab=idxName) %>% 
          dyRangeSelector()

        }else{
          mxUpdateText("wdiMsg",
            sprintf("No data returned for %1$s in %2$s"
              , idx
              , cnt
              )
            ) 
        }
      }
    }

    # In case of missing graphIndicator, create emtpy one
    if(!exists("graphIndicator")){
      graphIndicator <- dygraph(as.ts(data.frame(0)))
    } 

    output$dyGraphWdi <- renderDygraph(graphIndicator)
      })
})
