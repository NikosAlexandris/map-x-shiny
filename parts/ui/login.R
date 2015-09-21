## Login module;
div(style="width=100%",
  tags$ul(class="list-inline",
    #tags$li(textInput("loginEmail", "Email:")),
    tags$li(usrInput("loginUser", "User name")),  
    tags$li(pwdInput("loginKey", "Key")),  
    tags$li(actionButton("btnLogin", icon("sign-in"))),
    tags$li(actionButton("btnLogout", icon("sign-out"))),
    tags$li(textOutput("loginValidation"))
    )
  )

