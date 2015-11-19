#source("fun.R")
source("loadlib.R")
source("helper/R/mapx.R")
source('helper/R/handson.R')
source("settings/settings.R")
source("config.R")


# User interface
ui <- tagList(
  tags$head(
    # metas
    tags$meta(`http-equiv`="X-UA-Compatible",content="IE=edge"),
    tags$meta(name="viewport",content="width=device-width, initial-scale=1"),
    tags$meta(name="description", content=""),
    tags$meta(name="author", content=""),
    tags$meta(name="robots", content="noindex"),
    
    #style sheet
    tags$link(href="font-awesome-4.4.0/css/font-awesome.min.css",rel="stylesheet",type="text/css"),
    tags$link(href="theme/grayscale/bootstrap.min.css",rel="stylesheet",type="text/css"),
    tags$link(rel="stylesheet",type="text/css",href='handsontable/handsontable.full.min.css'),
    tags$link(rel="stylesheet",type="text/css",href='ionRangeSlider/css/ion.rangeSlider.css'),
    tags$link(rel="stylesheet",type="text/css",href='ionRangeSlider/css/ion.rangeSlider.skinNice.css'),
    tags$link(href="mapx/mapx.css",rel="stylesheet",type="text/css")
    ),
  # body
  tags$body(id="page-top",`data-spy`="scroll",`data-target`=".navbar-fixed-top", `data-offset`="0",
    # error panels
    uiOutput('panelAlert'),
    uiOutput('panelAlertCountry'),
    # sections
    loadUi("parts/ui/nav.R"),
    loadUi("parts/ui/intro.R"), 
    loadUi("parts/ui/login.R"),
    loadUi("parts/ui/country.R"),
    loadUi("parts/ui/map.R"),
    loadUi("parts/ui/about.R"),
    loadUi("parts/ui/admin.R"),
    loadUi("parts/ui/footer.R")
    ), 
  # Scripts loaded after ui parts
  tags$footer(
    # TODO: uglify and concat js files OR load with singleton when needed.

    # Tags$script(src="jquery.gridly/javascripts/jquery.gridly.js"),
    tags$script(src="chartjs/Chart.min.js"),
    tags$script(src="mapx/mapxChartJsConf.js"),
    tags$script(src="theme/grayscale/grayscale.js"),
    tags$script(src="theme/grayscale/jquery.easing.min.js"),
    # Use last version of bootstrap, dependencies of grayscale js!
    tags$script(src="bootstrap/js/bootstrap.min.js"),
    tags$script(src="pwd/pwd.js"),
    tags$script(src="pwd/md5.js"),
    tags$script(src="handsontable/handsontable.full.min.js"),
    tags$script(src="handsontable/shinyskyHandsonTable.js"),
    # ioRangeSlider is already present in shiny dependencies!
    tags$script(src="ionRangeSlider/js/ion-rangeSlider/ion.rangeSlider.min.js"),
    tags$script(src="mapx/mapx.js"),
    tags$script(src="language/ui.js")
    )
  )


#
# SERVER
#
server <- function(input, output, session) {
  #
  # load server parts
  #
  source("parts/server/global.R",local=TRUE)
  source("parts/server/urlParsing.R",local=TRUE)
  source("parts/server/login.R",local=TRUE)
  source("parts/server/nav.R",local=TRUE)
  source("parts/server/country.R",local=TRUE)
  source("parts/server/map.R",local=TRUE)
  source("parts/server/admin.R",local=TRUE)
  source("parts/server/analysis.R",local=TRUE)
  source("parts/server/tenke.R",local=TRUE)
} # end of server part


mxCatch(title="Main application",{
  shinyApp(ui, server)
  })



