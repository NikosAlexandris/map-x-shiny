#                             
#  _ __ ___   __ _ _ __   __  __
# | '_ ` _ \ / _` | '_ \  \ \/ /
# | | | | | | (_| | |_) |  >  < 
# |_| |_| |_|\__,_| .__/  /_/\_\
#                 | |           
#                 |_|           
# Admin panel

userPanel = tagList(
  p("Note: buttons doesn't do anything for now."),
  tags$ul(class="list-inline",
    tags$li(
      actionButton("btnAdmRmUser","Remove selected (test)"),
      actionButton("btnAdmUpdateUser","Update selected (test)")
      )
    ),
  div(class="mxTableContainer", hotable("tableUsers"))
 
  )

# views management panel
viewsPanel <- tagList(
  p("Note: update button does nothing yet."),
  tags$ul(class="list-inline",
    tags$li(
      actionButton("btnAdmRmViews","Remove selected (test)"),
      actionButton("btnAdmUpdateViews","Update selected (test)"),
      uiOutput("confirmRmViews")
      )
    ), 
  div(class="mxTableContainer",hotable("tableViews")) 
  )

# main structure
tags$section(id="sectionAdmin",class="container-fluid mx-hide",
  div(class="row",
    div(class="col-xs-12",
      h2("Admin"),
      actionButton("btnDebug",class="btn-default btn-lg","Show debugger"),
      hr(),
        tabsetPanel(type="pills",
          tabPanel("USERS", userPanel),
          tabPanel("VIEWS",  viewsPanel),
          tabPanel("LAYERS", p()),
          tabPanel("STORY MAPS",  p()),
          tabPanel("MAINTENANCE",p())
          )
      )
    )
  )

