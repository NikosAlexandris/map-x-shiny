#                             
#  _ __ ___   __ _ _ __   __  __
# | '_ ` _ \ / _` | '_ \  \ \/ /
# | | | | | | (_| | |_) |  >  < 
# |_| |_| |_|\__,_| .__/  /_/\_\
#                 | |           
#                 |_|           
# user login

tags$section(id="sectionLogin",class="container-fluid",
  div(class="row",
    div(class="col-lg-10 col-lg-offset-1",
      ## Login module;
      div(class="mxLogin",
        div(class="col-lg-4 col-md-6 col-xs-12",
          h2(mx_set_lang="html.login.title","User authentication")
          ),
        div(class="col-lg-8 col-md-6 col-xs-12"
       #   h6(textOutput("loginValidation")),
       #   div(class="col-lg-4 col-md-12 col-xs-12",
       #     usrInput("loginUser", "User name")
       #     ),
       #   div(class="col-lg-4 col-md-12 col-xs-12",
       #     pwdInput("loginKey", "Key")
       #     ),
       #   div(class="col-lg-4 col-md-12 col-xs-12",
       #   tags$ul(class="list-inline",
       #     tags$li(actionButton("btnLogin", icon("sign-in"))),
       #     tags$li(actionButton("btnLogout", icon("sign-out"))),
       #     tags$li( 
       #     mxSelectInput(
       #       inputId="selectLanguage",
       #       choices=c("fre","eng"),
       #       selected="fre"),
       #       onchange="updateTitlesLang()")
       #     )
       #   )
          )
        )
      )
    )
  )

