

# MAP SECTION 
#
    observe({
      mxUiEnable(id="sectionMap",enable=mxReact$allowMap) 
    })

    observe({
      mxUiEnable(id="btnViewsCreator",enable=mxReact$allowViewsCreator) 
    })
observe({
  if(mxReact$allowMap){
       #
    # CLEAR LAYER AFTER EXLORER MODE ENTER
    #

    observeEvent(input$btnViewsExplorer,{
        mxCatch(title="Clean creator layers",{
          mxStyle <- reactiveValues()
          dGroup <- mxConfig$defaultGroup
          legendId <- paste0(dGroup,"_legends")
          proxyMap <- leafletProxy("mapxMap")
          proxyMap %>%
          clearGroup(dGroup) %>% 
          removeControl(legendId) 
})
    })

    #
    # CLEAR LAYER AFTER CREATOR ENTER
    #


    observeEvent(input$btnViewsCreator,{
      mxCatch(title="Clean explorer layers",{
        mxStyle <- reactiveValues()
          mxReact$viewsToDisplay = ""
})
    })


    #
    # CLEAR LAYER AFTER TOOLBOX ENTER
    #
    
    observeEvent(input$btnViewsCreator,{
      mxCatch(title="Clean layers",{
        mxStyle <- reactiveValues()
          mxReact$viewsToDisplay = ""
})
    })


    #
    # MAIN MAP
    #

    output$mapxMap <- renderLeaflet({
        if(noDataCheck(mxReact$selectCountry))return()
        group = "main"
        iso3 <- mxReact$selectCountry
        if(!noDataCheck(iso3)){
          center <- mxConfig$countryCenter[[iso3]] 
          mxConfig$baseLayerByCountry(iso3,group,center)
        }
    })



    source("parts/server/creator.R",local=TRUE)
    #source('parts/server/upload.R',local=TRUE)
    source("parts/server/views.R",local=TRUE)
    source("parts/server/style.R",local=TRUE)
    source('parts/server/panelMode.R',local=TRUE)





  }

})
