

#
# set map panel mode TODO: clean this. Mode is stored in a visible javascrip object : not secure.
#

observe({
  if(mxReact$allowMap){
    mxCatch(title="set panel mode",{
      #
      # DEFAULT
      #

      output$titlePanelMode <- renderText({
        panelMode <- mxSetMapPanelMode(mode='mapViewsExplorer',title='Map views explorer')
        mxReact$mapPanelMode <- panelMode$mode
        panelMode$title
      })

      #
      # ACTION HANDLER
      #

      # Creator mode
      observeEvent(input$btnViewsCreator,{
        if(mxReact$allowViewsCreator){
          panelMode <- mxSetMapPanelMode(mode='mapViewsCreator',title='Map views creator')
          mxReact$mapPanelTitle = panelMode$title
          mxReact$mapPanelMode  = panelMode$mode
        }
      })

      # explorer mode
      observeEvent(input$btnViewsExplorer,{
        panelMode <- mxSetMapPanelMode(mode='mapViewsExplorer',title='Map views explorer')
        mxReact$mapPanelTitle <- panelMode$title
        mxReact$mapPanelMode  <- panelMode$mode
      })
      # config mode
      observeEvent(input$btnViewsConfig,{
        panelMode <- mxSetMapPanelMode(mode='mapViewsConfig',title='Map views config')
        mxReact$mapPanelTitle <- panelMode$title
        mxReact$mapPanelMode  <- panelMode$mode
      })
      # toolbox mode
      observeEvent(input$btnViewsToolbox,{
        panelMode <- mxSetMapPanelMode(mode='mapViewsToolbox',title='Spatial toolbox')
        mxReact$mapPanelTitle <- panelMode$title
        mxReact$mapPanelMode  <- panelMode$mode
      })
      #
      # UPDATE TITLE
      #
      observe({ 
        title <- mxReact$mapPanelTitle
        if(noDataCheck(title))return()
        output$titlePanelMode <- renderText({title}) 
      })
})
  }
})
