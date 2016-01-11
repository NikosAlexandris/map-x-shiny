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

s <- function(port=4848){
  library(shiny)
  runApp('.',port=port,launch.browser=FALSE)
}


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
  tags$head(
    tags$link(href="font-awesome-4.4.0/css/font-awesome.min.css",rel="stylesheet",type="text/css"),
    tags$link(href="theme/grayscale/bootstrap.min.css",rel="stylesheet",type="text/css"),
    tags$link(rel="stylesheet",type="text/css",href='handsontable/handsontable.full.min.css'),
    tags$link(rel="stylesheet",type="text/css",href='ionRangeSlider/css/ion.rangeSlider.css'),
    tags$link(rel="stylesheet",type="text/css",href='ionRangeSlider/css/ion.rangeSlider.skinNice.css'),
    tags$link(href="mapx/mapx.css",rel="stylesheet",type="text/css")
    ),
  # Scripts loaded after ui parts
  tags$footer(
    # TODO: uglify and concat js files OR load with singleton when needed.
    tags$script(src="mapx/mapx.js"),
    tags$script(src="mapx/base64.js"),
    tags$script(src="language/ui.js"),
    tags$script(src="bootstrap/js/bootstrap.min.js"),
    tags$script(src="pwd/pwd.js"),
    tags$script(src="pwd/md5.js"),
    tags$script(src="theme/grayscale/grayscale.js"),
    tags$script(src="theme/grayscale/jquery.easing.min.js"),
    tags$script(src="chartjs/Chart.min.js"),
    tags$script(src="mapx/mapxChartJsConf.js"),
    # Use last version of bootstrap, dependencies of grayscale js!
    tags$script(src="handsontable/handsontable.full.min.js"),
    tags$script(src="handsontable/shinyskyHandsonTable.js"),
    # Use the last version of ionRangeSlider
    tags$script(src="ionRangeSlider/js/ion-rangeSlider/ion.rangeSlider.min.js")
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


