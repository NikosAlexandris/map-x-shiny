#                             
#  _ __ ___   __ _ _ __   __  __
# | '_ ` _ \ / _` | '_ \  \ \/ /
# | | | | | | (_| | |_) |  >  < 
# |_| |_| |_|\__,_| .__/  /_/\_\
#                 | |           
#                 |_|           
# main server function

#
# R libraries (managed using packrat !)
#
source("loadlib.R")
#
# map-x functions (this will be transfered to a R package)
#
source("helper/R/mapx.R")
#
# leaflet R plugin : additional handler for drawing
#
source("helper/R/leafletDraw.R")
#
# handson table functions
#
source('helper/R/handson.R')
#
# general configuration, site independant.
#
source("settings/config-global.R")
#
# configuration specific to the host on wich map-x is launched
#
source("settings/config-local.R")

#
# Define main user interface
#
ui <- tagList(
  # alert panels
  uiOutput('panelAlert'),
  # sections
  loadUi("parts/ui/nav.R"),
  loadUi("parts/ui/intro.R"), 
  loadUi("parts/ui/map.R"),
  loadUi("parts/ui/country.R"),
  loadUi("parts/ui/about.R"),
  loadUi("parts/ui/admin.R"),
  loadUi("parts/ui/footer.R"),
  # Scripts loaded after ui parts : shiny bindings, dom init, etc.
  tags$footer(
    tagList(
      tags$script(src="src/mapx/js/mapxInit.js")
      )
    )
  )

shinyServer(function(input, output, session) {
  mxCatch(title="Main server function",{
     #
    # Initial reactive values
    #
    mxReact <- reactiveValues()
    mxStyle <- reactiveValues()
    #
    # Output ui
    #
    output$mapxUi <- renderUI(ui)

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
    # Load server parts
    #
    # Navigation and login
   
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


