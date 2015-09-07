

  #
  # set map panel mode TODO: clean this. Mode is stored in a visible javascrip object : not secure.
  #


  mxCatch(title="set panel mode",{
    # default
    output$titlePanelMode <- renderText({
      panelMode <- mxSetMapPanelMode(mode='mapViewsExplorer',title='Map view explorer')
      mxReact$mapPanelMode <- panelMode$mode
      panelMode$title
    })

    # Creator mode
    observeEvent(input$btnViewsCreator,{
      panelMode = mxSetMapPanelMode(mode='mapViewsCreator',title='Map views creator')
      mxReact$mapPanelTitle = panelMode$title
      mxReact$mapPanelMode  = panelMode$mode
    })

    # explorer mode
    observeEvent(input$btnViewsExplorer,{
      panelMode = mxSetMapPanelMode(mode='mapViewsExplorer',title='Map views explorer')
      mxReact$mapPanelTitle <- panelMode$title
      mxReact$mapPanelMode  <- panelMode$mode
    })

    # explorer mode
    observeEvent(input$btnViewsConfig,{
      panelMode = mxSetMapPanelMode(mode='mapViewsConfig',title='Map views config')
      mxReact$mapPanelTitle <- panelMode$title
      mxReact$mapPanelMode  <- panelMode$mode
    })



    observe({ 
      title <- mxReact$mapPanelTitle
      if(noDataCheck(title))return()
      output$titlePanelMode <- renderText({title}) 
    })


  })

