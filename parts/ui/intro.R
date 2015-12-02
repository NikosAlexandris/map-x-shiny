#                             
#  _ __ ___   __ _ _ __   __  __
# | '_ ` _ \ / _` | '_ \  \ \/ /
# | | | | | | (_| | |_) |  >  < 
# |_| |_| |_|\__,_| .__/  /_/\_\
#                 | |           
#                 |_|           
# Header

tags$section(id="sectionTop",class="intro container-fluid background-triangles",
  div(class="col-md-8 col-md-offset-2",
   h1("MAP-X"),
    hr(),
    tags$p(class="map-x-subtitle",
      "Mapping and Assessing the Performance of Extractive Industries in Emerging Economies and Fragile States."
      ),
    hr(),
    tags$div(class="map-x-logos",
      tags$img(src="img/intro_logo_grid_white_en.svg",class="map-x-logo"),
      tags$img(src="img/intro_world-bank-optimized.svg",class="map-x-logo"),
      tags$img(src="img/intro_g7-vect-optimized.svg",class="map-x-logo")
      ),
    hr(),
    div(class="col-xs-12",
      div(class="col-lg-4 col-md-12 col-xs-12",
        usrInput("loginUser", "User name")
        ),
      div(class="col-lg-4 col-md-12 col-xs-12",
        pwdInput("loginKey", "Key")
        ),
      div(class="col-lg-4 col-md-12 col-xs-12",
        tags$ul(class="list-inline",
          tags$li(actionButton("btnLogin", icon("sign-in"))),
          tags$li(actionButton("btnLogout", icon("sign-out")))
          )
        ),
      div(class="col-xs-12",
         h6(textOutput("loginValidation"))
    )
    )
  )
  )




