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
# Country input selection
#
observeEvent(input$selectCountry,{
  selCountry = input$selectCountry
  if(!noDataCheck(selCountry) && mxReact$userLogged){
    mxReact$selectCountry <- selCountry
    dat <- mxReact$userInfo
    selCountryOld <- mxGetListValue(
      li=dat,
      path=c("data","user","preferences","last_project")
      ) 

    if(!identical(toupper(selCountryOld),toupper(selCountry))){
      dat <- mxSetListValue(
        li=dat,
        path=c("data","user","preferences","last_project"),
        value=selCountry
        )
      
      mxDbUpdate(
        table=mxConfig$userTableName,
        idCol='id',
        id=dat$id,
        column='data',
        value=dat$data
        )

  

    }



  }
})


observe({
  cSelect <- mxReact$selectCountry
  
  if(!noDataCheck(cSelect)){
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
    #output$countryName <- renderText(countryName)
    #output$countryMetrics <- renderUI(countryMetrics)
    #output$countryNarrative <- renderUI(countryNarrative)
  }
})



#
# SHOW INDEX
#



observe({
  idx <- input$selectIndicator
  cnt <- mxReact$selectCountry
  msg <- ""
  if(!noDataCheck(idx) && !noDataCheck(cnt)){

    mxCatch("Plot WDI data",{

      if(!mxCanReach("data.worldbank.org")){
        msg <- "No connection to worldbank development index."
        mxUpdateText("wdiMsg",msg)
      }else{

        dat <- WDI(
          indicator = idx, 
          country = countrycode(cnt,'iso3c','iso2c'), 
          start = 1980, 
          end = 2016
          )

        dat = na.omit(dat)
        if(exists('dat') && nrow(dat)>0){
          dat$year <- as.Date(paste0(dat$year,'-12-31'))
          datSeries <- xts(dat[,idx],order.by=dat$year)
          idxName = names(mxConfig$wdiIndicators[idx])
          graphIndicator = dygraph(
            data=datSeries,
            main=idxName,
            ylab=idxName) %>% 
          dyRangeSelector()
          output$dyGraphWdi <- renderDygraph({
            graphIndicator
          })
      }}
        })
  }
})
