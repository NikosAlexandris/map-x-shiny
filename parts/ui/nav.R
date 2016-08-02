#                             
#  _ __ ___   __ _ _ __   __  __
# | '_ ` _ \ / _` | '_ \  \ \/ /
# | | | | | | (_| | |_) |  >  < 
# |_| |_| |_|\__,_| .__/  /_/\_\
#                 | |           
#                 |_|           
# navigation bar

tags$nav(id="navbarTop",class="navbar navbar-custom navbar-fixed-top mx-hide",role="navigation",
  div(class="container nav-mapx",
    div(class="navbar-header",
      # butto to activate navbar
      tags$button(type="button",class="navbar-toggle",`data-toggle`="collapse",`data-target`=".navbar-main-collapse", 
        div(style="font-size;18px;color:white;",icon('bars'))
        ),
      tags$div(
        id = "navBarCountryChoice",
        class = "navbar-brand",
        tags$img(src="img/logo_white.svg",class="mx-logo-small float-left"),
        tags$span(
          id="countryTitle",
          class="float-left on-top",
          onClick='classToggle("selectCountryPanel","mx-hide")'
          ),
        tags$span(
          id="selectCountryPanel",
          class="mx-panel-country-container col-xs-10 col-lg-8 mx-hide",
          tags$div(class="mx-arrow mx-arrow-up-white"),
          tags$div(class="mx-panel-country mx-shadow",
          selectizeInput(
            inputId = "selectCountry",
            label = "Select country",
            choices = c(mxConfig$countryListChoices,mxConfig$noData),
            selected= mxConfig$noData
            )
          )
          )
        )  
      ), 
    # nav bar
    div(class="collapse navbar-collapse navbar-right navbar-main-collapse",
      tags$ul(class="list-inline navbar-nav",
        tags$li(
          id="btnNavHome",
          mx_set_lang="title.navBar.home",
          class="btn btn-circle",
          onClick="enableSection('sectionTop')",
          tags$i(
            class="fa fa-home animated"
            )
          ), 
        tags$li(
          mx_set_lang="title.navBar.map",
          id="btnNavMap",
          class="btn btn-circle mx-hide",
          onClick="enableSection('sectionMap')",
          tags$i(
            class="fa fa-globe animated"
            )
          ),
        tags$li(
          mx_set_lang="title.navBar.country",
          id="btnNavCountry",
          class="btn btn-circle mx-hide",
          onClick="enableSection('sectionCountry')",
          tags$i(
            class="fa fa-flag animated"
            )
          ),
        tags$li(
          mx_set_lang="title.navBar.admin",
          id="btnNavSettings",
          class="page-scroll btn btn-circle mx-hide",
          onClick="enableSection('sectionAdmin')",
          tags$i(
            class="fa fa-cog animated"
            )
          ), 
        tags$li(
          mx_set_lang="title.navBar.tour",
          id="btnNavTour",
          class="btn btn-circle",
          onclick="mxStartTour(mxTour)",
          tags$i(class="fa fa-question animated"
            )
          ),
        tags$li(
          mx_set_lang="title.navBar.user",
          id="btnNavUser",
          class="btn btn-circle action-button",
          tags$i(
            class="fa fa-user animated"
            )
          )
        ) 
      )
    )
  )

