
  #
  # URL parsing and country selection
  #
  observe({
    mxCatch(title="Query url",{
      query <- parseQueryString(session$clientData$url_search,nested=TRUE)
      #
      # Country selection
      #
      if(isTRUE(
          query$country %in% mxConfig$countryListChoices$pending ||
          query$country %in% mxConfig$countryListChoices$potential
          )){
        sel = query$country
      }else{
        sel = mxConfig$defaultCountry
      }
      updateSelectInput(session,"selectCountry",selected=sel,choices=mxConfig$countryListChoices)
      updateSelectInput(session,"selectCountryNav",selected=sel,choices=mxConfig$countryListChoices)
      #
      # Language
      #
      if(isTRUE(query$language %in% c("eng","fre"))){
        lang=query$language
      }else{
        lang="eng"
      }
      updateSelectInput(session,"selectLanguage",selected=lang)
      #
      # views selection
      #
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

