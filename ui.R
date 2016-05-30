#
# Define main user interface
#

tagList(
  tags$head(
    tags$title("map-x"),
    tags$meta( `http-equiv`="X-UA-Compatible", content="IE=edge" ),
    tags$meta( `http-equiv`="Cache-control", content="private" ),
    tags$meta( name="viewport", content="width=device-width, initial-scale=1" ),
    tags$meta( name="description", content="" ),
    tags$meta( name="author", content="" ),
    tags$meta( name="robots", content="noindex" ), 
    tags$link( href="shared/shiny.css", rel="stylesheet" ),
    tags$link( href="dist/assets.css", rel="stylesheet", type="text/css" ),
    tags$link( href="/img/favicon.ico", rel="shortcut icon", type="image/x-icon" )
    ),
  tags$body(
    tags$section(
      id="sectionLoading",
      class="mx-section-container mx-section-top", 
      tags$h2( "MAP-X LOADING" ),
      tags$div( id="loading-image" )
      ),
    tags$div( id="page-wrapper",
      `data-spy`="scroll",
      `data-target`=".navbar-fixed-top",
      `data-offset`="0",
      class="no-scroll",
      tags$div(class="mx-section-content",
        tagList(
          # alert panels
          uiOutput('panelAlert'),
          # sections
          loadUi("parts/ui/nav.R"),
          loadUi("parts/ui/home.R"), 
          loadUi("parts/ui/map.R"),
          loadUi("parts/ui/country.R"),
          loadUi("parts/ui/about.R"),
          loadUi("parts/ui/admin.R")
          )
        ),
      tags$footer(
        tags$div(id="cookies",class="shinyCookies"),
        tags$script( src="dist/assets.js" ),
        tags$script( src="src/mapx/js/init.js" )
        )
      )
    )
  )  

