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
    #
    #
    observe({
      session$onFlushed(once=TRUE,function(){
        mxUiEnable(id="sectionLoading",enable=FALSE)
})
    })
    #
    # DB control
    #
    if(!mxDbExistsTable("mx_users")) stop("Users table missing")
    #
    # Init reactive values
    # 
    source("parts/server/reativeValues.R",local=TRUE)
    #
    # Load when "document is ready is called"
    #
    observeEvent(input$cookies,{
      reactUser$cookies <- input$cookies
      mxConsoleText("map-x is launched")
      mxSendJson("data/tour.json","mxTour")
      source("parts/server/login.R",local=TRUE)
      source("parts/server/nav.R",local=TRUE)
      source("parts/server/urlParsing.R",local=TRUE)
    }) 
    #
    # Country panel
    #
    observe({
      if(isTRUE(reactUser$allowCountry)){
        source("parts/server/country.R",local=TRUE)
      }
    })
    #
    # Map panel
    #
    observe({
      if(isTRUE(reactUser$allowMap)){
        source("parts/server/map.R",local=TRUE)
        source("parts/server/wms.R",local=TRUE)
        source("parts/server/tenke.R",local=TRUE)
      }
    })
    #
    # Settings panel
    #
    observe({
      if(isTRUE(reactUser$allowProfile)){
        source("parts/server/admin.R",local=TRUE)
      }
    })

})

})


