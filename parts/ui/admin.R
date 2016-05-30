#                             
#  _ __ ___   __ _ _ __   __  __
# | '_ ` _ \ / _` | '_ \  \ \/ /
# | | | | | | (_| | |_) |  >  < 
# |_| |_| |_|\__,_| .__/  /_/\_\
#                 | |           
#                 |_|           
# Admin panel




userPanel = tagList(
uiOutput("sectionUserManage")  
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



tags$section(id="sectionAdmin",class="mx-section-container container-fluid mx-hide",
  tagList(
    div(class="row",
      div(class="col-lg-10 col-lg-offset-1",
      h2("Admin"),
      hr(),
        tabsetPanel(type="pills",
          tabPanel("USERS", userPanel),
          tabPanel("VIEWS",  viewsPanel),
          tabPanel("LAYERS", p()),
          tabPanel("STORY MAPS",  p()),
          tabPanel("MAINTENANCE",p())
          ),
      actionButton("btnDebug",class="btn-default btn-lg","Show debugger")
      )
    )
  )
)

