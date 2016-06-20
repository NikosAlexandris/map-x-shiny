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
observeEvent(session$clientData,{
  mxCatch(title="Query url",{

    clientData <- session$clientData

    #
    # vector tiles configuration based on host
    #

    host <- clientData$url_hostname

    if(isTRUE(grepl("mapx",host))){
      mxConfig$vtInfo <<- list(
        protocol = "https",
        port = "",
        host = host,
        geom = "geom",
        gid = "gid"
        )
    }else{
      mxConfig$vtInfo <<- list(
        protocol = "http",
        port = 8080,
        host = host,
        geom = "geom",
        gid = "gid"
        )
    }

    query <- parseQueryString(clientData$url_search,nested=TRUE)

    ##
    ## COOKIES
    ##
    #cookies = list(
    #language = input$cookiesLanguage,
    #country = input$cookiesCountry
    #)
    ## does not work on shiny server   cookies <- mxGetCookies()

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
      cntry <- toupper(query$country)
      updateSelectInput(session,"selectCountry",selected=cntry)
    }


    #
    # Language
    #
    # code "ISO 639-2"
    #  if(
    #isTRUE(tolower(query$language) %in% mxConfig$languageList)
    #){
    ## guet lang from query
    #lang <- query$language
    #}else if(
    #!noDataCheck(cookies$language)
    #){
    #lang <- cookies$language
    #}else{
    #lang <- mxConfig$defaultLanguage
    #}
    #updateSelectInput(session,"selectLanguage",selected=lang)
    #
    # views selection
    #
    if(!is.null(query$views)){
      views <- unlist(strsplit(subPunct(query$views,";"),";"))
      if(!noDataCheck(views)){
        isolate({
          reactMap$viewsDataFromUrl <- unique(views)
        })
      }
    }
})
})

