#                             
#  _ __ ___   __ _ _ __   __  __
# | '_ ` _ \ / _` | '_ \  \ \/ /
# | | | | | | (_| | |_) |  >  < 
# |_| |_| |_|\__,_| .__/  /_/\_\
#                 | |           
#                 |_|           
# Read tenke info file 



# presentation de tenke "demo case"
observeEvent(input$tenke,{
  tenkeTest <-  includeHTML("parts/ui/tenke-info.html")
  output$`info-box-content` <- renderUI(tenkeTest)
})



