


# presentation de tenke "demo case"



observeEvent(input$tenke,{
  test <- includeHTML("parts/ui/tenke-info.html")
  output$`info-box-content` <- renderUI(test)
  })



