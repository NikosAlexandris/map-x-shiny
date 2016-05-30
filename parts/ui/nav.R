#                             
#  _ __ ___   __ _ _ __   __  __
# | '_ ` _ \ / _` | '_ \  \ \/ /
# | | | | | | (_| | |_) |  >  < 
# |_| |_| |_|\__,_| .__/  /_/\_\
#                 | |           
#                 |_|           
# navigation bar

tags$nav(id="navbarTop",class="navbar navbar-custom navbar-fixed-top",role="navigation",
  div(class="container nav-mapx",
    div(class="navbar-header",
      # butto to activate navbar
      tags$button(type="button",class="navbar-toggle",`data-toggle`="collapse",`data-target`=".navbar-main-collapse", 
        div(style="font-size;18px;color:white;",icon('bars'))
        ),
      tags$div(
        class="navbar-brand",
        onClick="goTo('sectionCountry')",
        tags$img(src="img/logo_white.svg",class="mx-logo-small float-left"),
        tags$div(id="countryTitle",class="float-right")
        )
      ), 
    # nav bar
    div(class="collapse navbar-collapse navbar-right navbar-main-collapse",
      tags$ul(class="list-inline navbar-nav",
        tags$li(
          id="btnNavHome",
          mx_set_lang="title.navBar.home",
          class="btn btn-circle",
          onClick="goTo('sectionTop')",
          tags$i(class="fa fa-home animated"
            )
          ), 
        tags$li(
          mx_set_lang="title.navBar.map",
          id="btnNavMap",
          class="btn btn-circle mx-hide",
          onClick="goTo('sectionMap')",
          tags$i(
            class="fa fa-globe animated"
            )
          ),
        tags$li(
          mx_set_lang="title.navBar.country",
          id="btnNavCountry",
          class="btn btn-circle mx-hide",
          onClick="goTo('sectionCountry')",
          tags$i(
            class="fa fa-flag animated"
            )
          ),
        tags$li(
          mx_set_lang="title.navBar.about",
          id="btnNavAbout",
          class="page-scroll btn btn-circle",
          onClick="goTo('sectionAbout')",
          tags$i(
            class="fa fa-info animated"
            )
          ),
        tags$li(
          mx_set_lang="title.navBar.admin",
          id="btnNavAdmin",
          class="page-scroll btn btn-circle mx-hide",
          onClick="goTo('sectionAdmin')",
          tags$i(
            class="fa fa-wrench animated"
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
          mx_set_lang="title.navBar.logout",
          id="btnNavLogout",
          class="btn btn-circle mx-hide action-button",
          tags$i(
            class="fa fa-sign-out animated"
            )
          )
        ) 
      )
    )
  )

