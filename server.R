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
    # DB control
    #
    if(!mxDbExistsTable("mx_users")) stop("Users table missing")

    observe({
      session$onFlushed(once=TRUE,function(){
        mxUiEnable(id="sectionLoading",enable=FALSE)
})
    })



   #
    # Initial reactive values
    #
    mxReact <- reactiveValues()
    mxStyle <- reactiveValues()
    #
    #
    #
    
    #
    # Load when "document is ready is called"
    #
    observeEvent(input$cookies,{
      mxReact$cookies <- input$cookies
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
      if(isTRUE(mxReact$allowCountry)){
        source("parts/server/country.R",local=TRUE)
      }
    })
    #
    # Map panel
    #
    observe({
      if(isTRUE(mxReact$allowMap)){
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


