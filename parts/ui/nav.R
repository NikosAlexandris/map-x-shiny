#                             
#  _ __ ___   __ _ _ __   __  __
# | '_ ` _ \ / _` | '_ \  \ \/ /
# | | | | | | (_| | |_) |  >  < 
# |_| |_| |_|\__,_| .__/  /_/\_\
#                 | |           
#                 |_|           
# navigation bar

tags$nav(class="navbar navbar-custom navbar-fixed-top",role="navigation",
  div(class="container nav-mapx",
    div(class="navbar-header",
      # butto to activate navbar
      tags$button(type="button",class="navbar-toggle",`data-toggle`="collapse",`data-target`=".navbar-main-collapse", 
        div(style="font-size;18px;color:white;",icon('bars'))
        ),
      # country title
      tags$a(id="countryTitleLarge",class="visible-lg navbar-brand page-scroll",href="#sectionCountry"),
      tags$a(id="countryTitleMedium",class="visible-md navbar-brand page-scroll",href="#sectionCountry"),
      tags$a(id="countryTitleSmall",class="visible-sm navbar-brand page-scroll",href="#sectionCountry"),
      tags$a(id="countryTitleMini",class="visible-xs navbar-brand page-scroll",href="#sectionCountry")
      ),
      # nav bar
      div(class="collapse navbar-collapse navbar-right navbar-main-collapse",
        tags$ul(class="list-inline navbar-nav",
          tags$li(
            class="hidden",
            tags$a(href="#page-top")
            ),
          tags$li(
            tags$a(
              id="btnNavHome",
              mx_set_lang="title.navBar.home",
              class="page-scroll btn btn-circle",
              href="#sectionTop",
              tags$i(class="fa fa-home animated")
              )
            ), 
          tags$li(
            tags$a(
              mx_set_lang="title.navBar.map",
              id="btnNavMap",
              class="page-scroll btn btn-circle mx-hide",
              href="#sectionMap",
              tags$i(
                class="fa fa-globe animated")
              )
            ),
          tags$li(
            tags$a(
              mx_set_lang="title.navBar.country",
              id="btnNavCountry",
              class="page-scroll btn btn-circle mx-hide",
              href="#sectionCountry",
              tags$i(
                class="fa fa-flag animated")
              )
            ),
          tags$li(
            tags$a(
              mx_set_lang="title.navBar.about",
              id="btnNavAbout",
              class="page-scroll btn btn-circle",
              href="#sectionAbout",
              tags$i(
                class="fa fa-info animated")
              )
            ),
          tags$li(
            tags$a(
              mx_set_lang="title.navBar.admin",
              id="btnNavAdmin",
              class="page-scroll btn btn-circle mx-hide",
              href="#sectionAdmin",
              tags$i(
                class="fa fa-wrench animated")
              )
            ),
          tags$li(
            tags$a(
              mx_set_lang="title.navBar.contact",
              id="btnNavContact",
              class="page-scroll btn btn-circle",
              href="#sectionContact",
              tags$i(class="fa fa-comment-o animated")
              )
            ),
          tags$li(
            tags$a(
              mx_set_lang="title.navBar.tour",
              id="btnNavTour",
              class="btn btn-circle",
              onclick="mxStartTour(mxTour)",
              tags$i(class="fa fa-question animated")
              )
            )
          ) 
        )
      )
    )
 
