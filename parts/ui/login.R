  #
  # contact
  #
tags$section(id="sectionLogin",class="container-fluid",
  div(class="row",
    div(class="col-lg-8 col-lg-offset-2",
## Login module;
div(class="mxLogin",
  tags$ul(class="list-inline",
    #tags$li(textInput("loginEmail", "Email:")),
    tags$li(usrInput("loginUser", "User name")),  
    tags$li(pwdInput("loginKey", "Key")),  
    tags$li(actionButton("btnLogin", icon("sign-in"))),
    tags$li(actionButton("btnLogout", icon("sign-out"))),
    tags$li(textOutput("loginValidation"))
    )
  )
      )
    )
  )

