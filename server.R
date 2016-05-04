#                             
#  _ __ ___   __ _ _ __   __  __
# | '_ ` _ \ / _` | '_ \  \ \/ /
# | | | | | | (_| | |_) |  >  < 
# |_| |_| |_|\__,_| .__/  /_/\_\
#                 | |           
#                 |_|           
# main server function


shinyServer(function(input, output, session) {
  mxCatch(title="Main server function",{
    


    #
    # Initial reactive values
    #
    mxReact <- reactiveValues()
    mxStyle <- reactiveValues()
    #
    # Init job
    #
    output$mapxInit <- renderUI({ 
      mxConsoleText("load init script")
      tags$script( src="src/mapx/js/mapxInit.js" )
    })
    #
    # Load when "document is ready is called"
    #
    observeEvent(input$documentIsReady,{
      mxConsoleText("")
      mxConsoleText(" map-x is launched ")
      mxConsoleText("")
      mxSendJson("data/tour.json","mxTour")
      source("parts/server/login.R",local=TRUE)
      source("parts/server/nav.R",local=TRUE)
      source("parts/server/urlParsing.R",local=TRUE)
    }) 
    #
    # Country panel
    #
    observe({
      if(isTRUE(mxReact$allowCountry)){
        source("parts/server/country.R",local=TRUE)
      }
    })
    #
    # Map panel
    #
    observe({
      if(isTRUE(mxReact$allowMap)){
        mxDebugMsg("map module loading")
        source("parts/server/map.R",local=TRUE)
        source("parts/server/wms.R",local=TRUE)
        source("parts/server/tenke.R",local=TRUE)
      }
    })
    #
    # Administration panel
    #
    observe({
      if(isTRUE(mxReact$allowAdmin)){
        source("parts/server/admin.R",local=TRUE)
      }
    })

})

})


