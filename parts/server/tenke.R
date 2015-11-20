


# presentation de tenke "demo case"
observeEvent(input$tenke,{
  tenkeTest <-  includeHTML("parts/ui/tenke-info.html")
  output$`info-box-content` <- renderUI(tenkeTest)
})



