


observe({
  # default
  navMenuDefault <- tagList(
    tags$li(class="hidden",tags$a(href="#page-top")),
    tags$li(tags$a(class="page-scroll btn btn-circle",href="#sectionTop",tags$i(class="fa fa-home animated"))),
    tags$li(tags$a(class="page-scroll btn btn-circle",href="#sectionAbout",tags$i(class="fa fa-info animated")))
    )

  # restricted
  navMenuResticted <- tagList(
    navMenuDefault,
    tags$li(tags$a(class="page-scroll btn btn-circle",href="#sectionCountry",tags$i(class="fa fa-bar-chart animated"))),
    tags$li(tags$a(class="page-scroll btn btn-circle",href="#sectionMap",tags$i(class="fa fa-map-o animated"))),
    tags$li(tags$a(class="page-scroll btn btn-circle",href="#sectionContact",tags$i(class="fa fa-comment-o animated")))
    )


  navMenu <- mxUiAccess(
    logged = mxReact$mxLogged,
    roleNum = mxConfig$rolesVal[[mxReact$mxRole]],
    roleLowerLimit = 100,
    uiDefault = navMenuDefault,
    uiRestricted = navMenuResticted
    )

  navMenu <- tagList(
   div(class="collapse navbar-collapse navbar-right navbar-main-collapse",
      tags$ul(class="nav navbar-nav",
      navMenu  
        )
      )
   )
output$navMenu <- renderUI(navMenu)
})




