#                             
#  _ __ ___   __ _ _ __   __  __
# | '_ ` _ \ / _` | '_ \  \ \/ /
# | | | | | | (_| | |_) |  >  < 
# |_| |_| |_|\__,_| .__/  /_/\_\
#                 | |           
#                 |_|           
# Header

tags$section(
  id="sectionTop",
  class="mx-section-container mx-section-top container-fluid",
  tags$div(
    class="mx-section-content",
    div(
      id="sectionTopPanel",
      class="col-md-8 col-md-offset-2",
      div(
        class="mx-title","MAP-X"),
      tags$div(
        class="mx-subtitle hidden-xs",
        p("Mapping and Assessing the Performance of Extractive Industries in Emerging Economies and Fragile States.")
        ),
      tags$div(class="hidden-xs",
        hr(),
        tags$img(
          src="img/intro_logo_grid_white_en.svg",
          height="50px",
          class="mx-logo"
          ),
        tags$img(
          src="img/intro_world-bank-optimized.svg",
          height="50px",
          class="mx-logo"
          ),
        tags$img(
          src="img/intro_g7-vect-optimized.svg",
          height="50px",
          class="mx-logo"
          ),
        hr()
        ),
      tags$div(class="hidden-md hidden-sm hidden-lg",
        hr(),
        tags$img(
          src="img/intro_logo_grid_white_en.svg",
          height="30px",
          class="mx-logo-medium"
          ),
        tags$img(
          src="img/intro_world-bank-optimized.svg",
          height="30px",
          class="mx-logo-medium"
          ),
        tags$img(
          src="img/intro_g7-vect-optimized.svg",
          height="30px",
          class="mx-logo-medium"
          ),
        hr()
        ),
      div(
        id="mxPanelLoginContainer",
        class="col-xs-12 col-lg-6 col-lg-offset-3",
        div(
          id="mxPanelLogin",
          class="input-group mx-login-group mx-hide",
          usrInput(
            inputId="loginUserEmail",
            label="Email",
            class="mx-login-input-white form-control"
            ),
          tags$span(
            class="input-group-btn",   
            actionButton(
              inputId="btnLogin", 
              label=icon("sign-in"),
              class="btn-square mx-hide"
              )
            ) 
          ),
        div(
          span(
            id="txtDialogLoginInput")
          )

        )
      )
    )
  )

