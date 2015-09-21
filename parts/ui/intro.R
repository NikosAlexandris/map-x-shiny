
  #
  # HEADER
  #
tags$section(id="sectionTop",class="intro container-fluid",
  div(class="col-md-8 col-md-offset-2",
    h1(class='map-x-title',"MAP-X"),
    hr(),
    tags$p(class="map-x-subtitle",
      "Mapping and Assessing the Performance of Extractive Industries in Emerging Economies and Fragile States."
      ),
    hr(),
    tags$div(class="map-x-logos",
      tags$img(src="img/logo_grid_white_en.svg",class="map-x-logo"),
      tags$img(src="img/world-bank-optimized.svg",class="map-x-logo"),
      tags$img(src="img/g7-vect-optimized.svg",class="map-x-logo")
      #tags$img(src="img/g7plus.png",class="map-x-logo")
      ),
    hr(),
    loadUi('parts/ui/login.R')
    )
  )





