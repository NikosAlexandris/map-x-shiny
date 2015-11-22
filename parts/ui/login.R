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
        h2(mx_set_lang="html.login.title","User authentication"),
        tags$ul(class="list-inline",
          #tags$li(textInput("loginEmail", "Email:")),
          tags$li(usrInput("loginUser", "User name")),  
          tags$li(pwdInput("loginKey", "Key")),  
          tags$li(mxSelectInput(inputId="selectLanguage",choices=c("fre","eng"),selected="fre"),onchange="updateTitlesLang()"),
          tags$li(actionButton("btnLogin", icon("sign-in"))),
          tags$li(actionButton("btnLogout", icon("sign-out"))),
          tags$li(textOutput("loginValidation"))
          )
        )
      )
    )
  )

