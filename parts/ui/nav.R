#                             
#  _ __ ___   __ _ _ __   __  __
# | '_ ` _ \ / _` | '_ \  \ \/ /
# | | | | | | (_| | |_) |  >  < 
# |_| |_| |_|\__,_| .__/  /_/\_\
#                 | |           
#                 |_|           
# navigation bar

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
        tags$li(
          class="hidden",
          tags$a(href="#page-top")
          ),
        tags$li(
          tags$a(
            mx_set_lang="title.navBar.home",
            class="page-scroll btn btn-circle",
            href="#sectionTop",
            tags$i(class="fa fa-home animated")
            )
          ),

   #     tags$li(
   #       tags$a(
   #         mx_set_lang="title.navBar.profil",
   #         class="page-scroll btn btn-circle",
   #         href="#sectionLogin",
   #         tags$i(
   #           class="fa fa-user animated")
   #         )
   #       ),
     #   tags$li(
     #     actionLink(
     #       mx_set_lang="title.navBar.profil",
     #       inputId="btnNavLogin",
     #       class="btn btn-circle",
     #       label=tags$i(
     #         class="fa fa-bar-chart animated")
     #       )
     #       )
     #     ),
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
          )

        ) 
      )
    )
  ) 
