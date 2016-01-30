#                             
#  _ __ ___   __ _ _ __   __  __
# | '_ ` _ \ / _` | '_ \  \ \/ /
# | | | | | | (_| | |_) |  >  < 
# |_| |_| |_|\__,_| .__/  /_/\_\
#                 | |           
#                 |_|           
# Header

tags$section(id="sectionTop",class="mx-section-container mx-section-top container-fluid",
  tags$div(class="mx-section-content",
    div(id="sectionTopPanel",class="col-md-8 col-md-offset-2",
      h1("MAP-X"),
      tags$div(class="map-x-subtitle hidden-xs",
        hr(),
        p("Mapping and Assessing the Performance of Extractive Industries in Emerging Economies and Fragile States."),
        hr()
        ),
      tags$div(class="map-x-logos hidden-xs ",
        tags$img(src="img/intro_logo_grid_white_en.svg",class="map-x-logo"),
        tags$img(src="img/intro_world-bank-optimized.svg",class="map-x-logo"),
        tags$img(src="img/intro_g7-vect-optimized.svg",class="map-x-logo"),
        hr()
        ),
      div(class="col-xs-12",
        div(class="col-lg-4 col-sm-4 col-xs-12",
          usrInput("loginUser", "User name")
          ),
        div(class="col-lg-4 col-sm-4 col-xs-12",
          pwdInput("loginKey", "Key")
          ),
        div(class="col-lg-4 col-sm-4 col-xs-12",
          tags$ul(class="list-inline",
            tags$li(
              actionButton("btnLogin", icon("sign-in")
                )
              ),
            tags$li(
              actionButton("btnLogout", icon("sign-out")
                )
              ),
            tags$li(
              mxSelectInput(
                inputId="selectLanguage",
                choices=c("fre","eng"),
                selected="fre"),
              onchange="updateTitlesLang()"
              )
            )
          )
        ),
      div(class="col-xs-12",
        p(id="loginValidation")
        )
      )
    )
  )



