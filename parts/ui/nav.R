
#
# NAVBAR
#
tags$nav(class="navbar navbar-custom navbar-fixed-top",role="navigation",
  div(class="container",
    div(class="navbar-header",
      tags$button(type="button",class="navbar-toggle",`data-toggle`="collapse",`data-target`=".navbar-main-collapse", 
        div(style="font-size;18px;color:white;",icon('bars'))
        ),
      tags$a(class="navbar-brand page-scroll",href="#sectionCountry",
        uiOutput('countryNameNav')
        )
      ), 
    div(class="collapse navbar-collapse navbar-right navbar-main-collapse",
      tags$ul(class="nav navbar-nav",
        tags$li(class="hidden",tags$a(href="#page-top")),
        tags$li(tags$a(class="page-scroll btn btn-circle",href="#sectionTop",tags$i(class="fa fa-home animated"))),
        tags$li(tags$a(class="page-scroll btn btn-circle",href="#sectionLogin",tags$i(class="fa fa-user animated"))),
        tags$li(tags$a(class="page-scroll btn btn-circle",href="#sectionAbout",tags$i(class="fa fa-info animated"))),
        tags$li(tags$a(id="btnNavCountry",class="page-scroll btn btn-circle",href="#sectionCountry",tags$i(class="fa fa-bar-chart animated"))),
        tags$li(tags$a(id="btnNavMap",class="page-scroll btn btn-circle",href="#sectionMap",tags$i(class="fa fa-map-o animated"))),
        tags$li(tags$a(id="btnNavContact",class="page-scroll btn btn-circle",href="#sectionContact",tags$i(class="fa fa-comment-o animated")))
        ) 
      )
    )
  ) 
