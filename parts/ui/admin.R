#
# admin panel
#

tags$section(id="sectionAdmin",class="container-fluid",
  div(class="row",
    div(class="col-lg-8 col-lg-offset-2",
      h2("Admin panel"),
      tabsetPanel(
        tabsetPanel(
          tabPanel("USERS",  p()),
          tabPanel("LAYERS", p()),
          tabPanel("VIEWS",  p()),
          tabPanel("STORY MAPS",  p()),
          tabPanel("MAINTENANCE",p()),
          tabPanel("GAME")
          )
        )
      )
    )
  )

