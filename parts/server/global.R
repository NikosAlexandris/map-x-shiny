
  # Reactive object initialisation
  mxReact <- reactiveValues()
  mxStyle <- reactiveValues()


  # show debugger
observeEvent(input$btnDebug,{
  browser()
})

# Country selection
observe({
  selCountry = input$selectCountry
  if(!noDataCheck(selCountry) && mxReact$userLogged){
    mxReact$selectCountry = selCountry
  }
})

# Language selection
observe({
  selLanguage = input$selectLanguage
  if(!noDataCheck(selLanguage)){
    mxReact$selectLanguage = selLanguage
  } 
})


