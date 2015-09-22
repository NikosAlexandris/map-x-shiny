#
# admin panel
#


userPanel = tagList(
  div(class="mxTableContainer", hotable('userTable')),
  tags$ul(class="list-inline",
    tags$li(
      actionButton("btnAdmRmUser","Remove selected (test)"),
      actionButton("btnAdmUpdateUser","Update (test)")
      )
    )
  )





tags$section(id="sectionAdmin",class="container-fluid",
  div(class="row",
    div(class="col-xs-12",
      h2("Admin"),
      actionButton("btnDebug",class="btn-default btn-lg","Show debugger"),
      hr(),
        tabsetPanel(type="pills",
          tabPanel("USERS", userPanel),
          tabPanel("VIEWS",  p()),
          tabPanel("LAYERS", p()),
          tabPanel("STORY MAPS",  p()),
          tabPanel("MAINTENANCE",p())
          )
      )
    )
  )

