



#
# UI ACCESS
#
#
#observe({
#output$uiCountry <- renderUI(mxUiAccess(
#    logged = mxReact$mxLogged,
#    roleNum = mxConfig$rolesVal[[mxReact$mxRole]],
#    roleMax = 1000,
#    roleMin = 0,
#    uiDefault = tagList(),
#    uiRestricted = uiCountry
#    ))
#})
#
#
#
#

 

  #
  # Update ui with country data
  #

  observe({
    # mxCatch("Get country indicators",{
    cSelect <- mxReact$selectCountry
    if(!noDataCheck(cSelect)){
      if(cSelect %in% names(mxData$countryInfo)){
        cInfo  <- mxData$countryInfo[[cSelect]]
        # extract country metrics
        countryMetrics <-  tags$ul(class="list-group",
          tags$li(class="list-group-item",tags$b("GDP :"),tags$span(class="badge",cInfo[['gdp']])),
          tags$li(class="list-group-item",tags$b("HDI :"),tags$span(class="badge",cInfo[['hdi']])),
          tags$li(class="list-group-item",tags$b("Status EITI:"),tags$span(class="badge",cInfo[['eiti_status']])),
          tags$li(class="list-group-item",tags$b("Gvt. revenues:"),tags$span(class="badge",cInfo[['gvt_revenues']])),
          tags$li(class="list-group-item",tags$b("Comp. payments"),tags$span(class="badge",cInfo[['comp_payment']]))
          )
        countryNarrative <-
          div(class="narratives-background",
            HTML(cInfo[['story']])
            )
      }else{
        countryMetrics <- tags$b("[ No metrics available yet ]")
        countryNarrative <- tags$b("[ No narratives yet ]")
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

      cListChoice <- c(names(mxConfig$countryListChoices$potential),names(mxConfig$countryListChoices$pending))
      names(cListChoice) <- c(as.character(mxConfig$countryListChoices$potential),as.character(mxConfig$countryListChoices$pending))
      countryNameNav <- cListChoice[[cSelect]]




      navCountryName <- tagList(
          tags$img(src="img/logo_white.svg"),
          tags$span(countryNameNav)
        )

      output$countryName <- renderText(countryName)
      output$countryNameNav <- renderUI(navCountryName)
      output$countryMetrics <- renderUI(countryMetrics)
      output$countryNarrative <- renderUI(countryNarrative)
      #})
    }
  })



  #
  # SHOW INDEX
  #



  observe({

    mxCatch("Plot WDI data",{
      idx = input$selectIndicator
      cnt = mxReact$selectCountry

      if(!noDataCheck(idx) && !noDataCheck(cnt)){
        dat <- WDI(
          indicator = idx, 
          country = countrycode(cnt,'iso3c','iso2c'), 
          start = 1980, 
          end = 2015
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
        }
      }
  })
  })

