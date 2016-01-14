#                             
#  _ __ ___   __ _ _ __   __  __
# | '_ ` _ \ / _` | '_ \  \ \/ /
# | | | | | | (_| | |_) |  >  < 
# |_| |_| |_|\__,_| .__/  /_/\_\
#                 | |           
#                 |_|           
# main server function

# R libraries (managed using packrat !)
source("loadlib.R")
# map-x functions (this will be transfered to a R package)
source("helper/R/mapx.R")
source("helper/R/leafletDraw.R")
# handson table functions
source('helper/R/handson.R')
# general configuration, site independant.
source("settings/config-global.R")
# configuration specific to the host on wich map-x is launched
source("settings/config-local.R")

#
# Define main user interface
#
ui <- tagList(
  # error panels
  uiOutput('panelAlert'),
  # sections
  loadUi("parts/ui/nav.R"),
  loadUi("parts/ui/intro.R"), 
  #  loadUi("parts/ui/login.R"),
  loadUi("parts/ui/map.R"),
  loadUi("parts/ui/country.R"),
  loadUi("parts/ui/about.R"),
  loadUi("parts/ui/admin.R"),
  loadUi("parts/ui/footer.R"),
  # Scripts loaded after ui parts
  tags$footer(
    # TODO: uglify and concat js files OR load with singleton when needed.
    tagList(
      tags$script(src="mapx/mapx.js")
      )
    )
  )

shinyServer(function(input, output, session) {
  mxCatch(title="Main server function",{
    #
    # parse additional json data
    #
    observeEvent(input$documentIsReady,{
      mxDebugMsg("document is ready")
      mxSendJson("data/tour.json","mxTour")
      })
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
    # Load server parts
    #
    # Navigation and login
    source("parts/server/login.R",local=TRUE)
    source("parts/server/nav.R",local=TRUE)
    source("parts/server/urlParsing.R",local=TRUE)
    # Country panel
    observe({
      if(mxReact$allowCountry){
        source("parts/server/country.R",local=TRUE)
      }
    })
    # Map panel
    observe({
      if(mxReact$allowMap){
        source("parts/server/map.R",local=TRUE)
        source("parts/server/wms.R",local=TRUE)
        source("parts/server/tenke.R",local=TRUE)
      }
    })
    # Administration panel
    observe({
      if(mxReact$allowAdmin){
        source("parts/server/admin.R",local=TRUE)
      }
    })

    })

  })


