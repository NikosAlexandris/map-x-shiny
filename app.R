
#source("fun.R")
source("loadlib.R")
source("fun/helperUi.R")
source("settings/settings.R")
source("config.R")

# NOTE : mvt exemple in Documents/unep_grid/map-x/test/Leaflet.MapboxVectorTile-master/examples/


#
# UI
#

ui <- tagList(
  tags$head(
    #
    # METAS
    #
    tags$meta(`http-equiv`="X-UA-Compatible",content="IE=edge"),
    tags$meta(name="viewport",content="width=device-width, initial-scale=1"),
    tags$meta(name="description", content=""),
    tags$meta(name="author", content=""),
    tags$meta(name="robots", content="noindex"),
    #
    #STYLE SHEET
    #
    tags$link(href="font-awesome-4.4.0/css/font-awesome.min.css",rel="stylesheet",type="text/css"),
    tags$link(href="theme/grayscale/bootstrap.min.css",rel="stylesheet",type="text/css"),
    tags$link(href="mapx/mapx.css",rel="stylesheet",type="text/css")
    ),
  tags$body(id="page-top",`data-spy`="scroll",`data-target`=".navbar-fixed-top", `data-offset`="0",
    #
    # PANELS
    #
    # 
    # SECTIONS
    #
    loadUi('parts/ui/nav.R'),
    loadUi('parts/ui/intro.R'), 
    loadUi('parts/ui/login.R'),
    loadUi('parts/ui/about.R'),
    loadUi('parts/ui/country.R'),
    loadUi('parts/ui/map.R'),
    loadUi('parts/ui/footer.R')
    ),
  #
  # Scripts
  #
  tags$head(
    # TODO: uglify and concat js files
    tags$script(src="chartjs/Chart.min.js"),
    tags$script(src="mapx/mapxChartJsConf.js"),
    tags$script(src="theme/grayscale/grayscale.js"),
    tags$script(src="theme/grayscale/jquery.easing.min.js"),
    tags$script(src="bootstrap/js/bootstrap.min.js"),
    tags$script(src="pwd/pwd.js"),
    tags$script(src="pwd/md5.js"),
    tags$script(src="mapx/mapx.js")
    )
  )





#
# Server
#
server <- function(input, output, session) {

  #
  # md5 hashed pwd
  #

  # u = user
  # l = login
  # k = key
  # e = email
  # r = role
  pwd <- rbind(
    c(id=0,u="fred", l="570a90bfbf8c7eab5dc5d4e26832d5b1",k="570a90bfbf8c7eab5dc5d4e26832d5b1", r="superuser"),
    c(id=1,u="pierre",l="84675f2baf7140037b8f5afe54eef841" ,k="84675f2baf7140037b8f5afe54eef841", r="superuser"),
    c(id=2,u="david",l="172522ec1028ab781d9dfd17eaca4427",k="172522ec1028ab781d9dfd17eaca4427", r="admin"),
    c(id=3,u="dag",l="b4683fef34f6bb7234f2603699bd0ded", k="b4683fef34f6bb7234f2603699bd0ded", r="admin"),
    c(id=4,u="nicolas",l="deb97a759ee7b8ba42e02dddf2b412fe", k="deb97a759ee7b8ba42e02dddf2b412fe", r="admin"),
    c(id=5,u="paulina",l="e16866458c9403fe9fb3df93bd4b3a41", k="e16866458c9403fe9fb3df93bd4b3a41", r="admin"),
    c(id=5,u="greg",l="ea26b0075d29530c636d6791bb5d73f4",k="ea26b0075d29530c636d6791bb5d73f4", r="user")
    )
  pwd<-as.data.frame(pwd,stringsAsFactors=F)
  #
  # show debugger
  #
  observeEvent(input$btnDebug,{
    browser()
  })


  #
  # Reactive object initialisation
  #

  mxReact <- reactiveValues()
  mxStyle <- reactiveValues()


  
  mxReact$uiDisplayMap = FALSE



  #
  # load server parts
  #
  source('parts/server/login.R',local=TRUE)
  source('parts/server/nav.R',local=TRUE)
  source('parts/server/country.R',local=TRUE)
  source('parts/server/map.R',local=TRUE)


 
  #
  # URL parsing and country selection
  #

  observe({
    mxCatch(title="Query url",{
      query <- parseQueryString(session$clientData$url_search,nested=TRUE)

      if(isTRUE(query$country %in% mxConfig$countryListChoices$pending || query$country %in% mxConfig$countryListChoices$potential)){
        sel = query$country
      }else{
        sel = "AFG"
      }
      updateSelectInput(session,'selectCountry',selected=sel,choices=mxConfig$countryListChoices)
      updateSelectInput(session,'selectCountryNav',selected=sel,choices=mxConfig$countryListChoices)
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


  observe({
    selCountry = input$selectCountry
    if(!noDataCheck(selCountry) && mxReact$mxLogged){
      mxReact$selectCountry = selCountry
    }
  })



} # end of server object


mxCatch(title="Main application",{
  shinyApp(ui, server)
})

