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
# map-x general functions 
#
source("helper/R/mxMisc.R")
#
# map-x ui functions 
#
source("helper/R/mxUi.R")
#
# leaflet R plugin : draw
#
source("helper/R/mxDraw.R")
#
# add vector tiles in "mapbox gl" or "leaflet mapbox vector tiles"
#
source("helper/R/mxVtDep.R")
#
# helper to get info on available pgrestapi layers
#
source("helper/R/mxPgRest.R")
#
# Helper for postgis request
#
source("helper/R/mxDb.R")
#
# handson table functions
#
source('helper/R/mxHandson.R')
#
# general configuration, site independant.
#
source("settings/config-global.R")
#
# configuration specific to the host on wich map-x is launched
#
source("settings/config-local.R")


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


