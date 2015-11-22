#                             
#  _ __ ___   __ _ _ __   __  __
# | '_ ` _ \ / _` | '_ \  \ \/ /
# | | | | | | (_| | |_) |  >  < 
# |_| |_| |_|\__,_| .__/  /_/\_\
#                 | |           
#                 |_|           
# contact panel

tags$section(id="sectionContact",class="container-fluid",
  div(class="row",
    div(class="col-lg-8 col-lg-offset-2",
      h2("Contact MAP-X team"),
      p("Feel free to repport any issues and feedback"),
      tags$ul(class="list-inline banner-social-buttons",
        tags$li(
          tags$a(href="https://twitter.com",class="btn btn-default btn-lg",tags$i(class="fa fa-twitter fa-fw"),tags$span(class="network-name","Twitter")),
          tags$a(href="https://github.com/unep-grid",class="btn btn-default btn-lg",tags$i(class="fa fa-github fa-fw"),tags$span(class="network-name","Github"))
          )
        )
      )
    )
  )

