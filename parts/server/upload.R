

  #
  # Data imporation manager
  #

  observeEvent(input$importData_spatial,{
    output$mxPanelModal <- renderUI({
      mxPanelModal(
        width=500,
        title="Data importation",
        subtitle="Import vector spatial dataset into map-x database.",
        html=tagList(
          uiOutput("importManager")
          ),
        defaultButtonText="cancel"
        )
    })
  })


  #
  # Data importation choose file
  #


  observe({
    dummy <- input$importData_spatial
    output$importManager <- renderUI({ tagList(
      tabsetPanel(type="pills",
        tabPanel(p("1"),tagList(
            fileInput("importData","Choose dataset",multiple=TRUE),
            p(lorem)
            )),
        tabPanel(p("2"),p("test")),
        tabPanel(p("3"),p("test"))
        )
      ) 
        })
  })


  #
  # Table importation
  #


  observeEvent(input$importData_table,{
    output$mxPanelModal <- renderUI({
      mxPanelModal(
        width=500,
        title="Table importation",
        subtitle="Import table dataset into map-x database.",
        html=tagList(
          p("test")
          ),
        listActionButton=list(
          actionButton("btnImportTest","submit test")
          ),
        background=FALSE
        )
    })
  })

