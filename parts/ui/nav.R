
#
# NAVBAR
#
tags$nav(class="navbar navbar-custom navbar-fixed-top",role="navigation",
  div(class="container",
    div(class="navbar-header",
      tags$button(type="button",class="navbar-toggle",`data-toggle`="collapse",`data-target`=".navbar-main-collapse", 
        div(style="font-size;18px;color:white;",icon('bars'))
        ),
      # tags$a(class="navbar-brand page-scroll",href="#page-top",
      div(class="navbar-brand page-scroll",
        mxSelectInput("selectCountryNav",choices="")
        #uiOutput('countryNameNav')
        )
      ), 
    uiOutput("navMenu")
    #   tags$li(class="dropdown",tags$a(id="menuCountry",class="dropdown-toggle",`data-toggle`="dropdown",href="#","Country",tags$span(class="caret")),
    #     tags$ul(class="dropdown-menu",
    #       uiOutput('countryDropDown')
    #       #mxConfig$countryListHtml
    #       )
    #     )
    ) 
  ) 


