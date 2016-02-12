#                             
#  _ __ ___   __ _ _ __   __  __
# | '_ ` _ \ / _` | '_ \  \ \/ /
# | | | | | | (_| | |_) |  >  < 
# |_| |_| |_|\__,_| .__/  /_/\_\
#                 | |           
#                 |_|           
# URL Parsing for country and views

#
# URL parsing and country selection
#
observe({
  mxCatch(title="Query url",{

    query <- parseQueryString(session$clientData$url_search,nested=TRUE)


    #
    # COOKIES
    #
    cookies <- mxGetCookies()

    #
    # Country selection
    #
    # code "ISO_3166-1_alpha-3"
    if(
      isTRUE(toupper(query$country) %in% c(
          mxConfig$countryListChoices$pending,
          mxConfig$countryListChoices$potential
          )
        )
      ){
      # get country from query
      cntry <- query$country
    }else if(
      !noDataCheck(cookies$country)
      ){
      # if no vale from query but something from cookie, use cookie
      cntry <- cookies$country
    }else{
      # default 
      cntry <- mxConfig$defaultCountry
    }

    updateSelectInput(session,"selectCountry",selected=cntry,choices=mxConfig$countryListChoices)

    #
    # Language
    #
    # code "ISO 639-2"
    if(
      isTRUE(tolower(query$language) %in% mxConfig$languageList)
      ){
      # guet lang from query
      lang <- query$language
    }else if(
      !noDataCheck(cookies$lang)
      ){
      lang <- cookies$lang
    }else{
      lang <- mxConfig$defaultLanguage
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

