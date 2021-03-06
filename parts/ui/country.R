#                             
#  _ __ ___   __ _ _ __   __  __
# | '_ ` _ \ / _` | '_ \  \ \/ /
# | | | | | | (_| | |_) |  >  < 
# |_| |_| |_|\__,_| .__/  /_/\_\
#                 | |           
#                 |_|           
# country analysis 

tags$section(id="sectionCountry",class="mx-section-container container-fluid mx-hide",
  tagList(
    div(class="row",
      div(class="col-lg-10 col-lg-offset-1",
        h2(id='countryName'),
        div(class="col-md-6 col-xs-12 text-left",
          h3('Key metrics'),
         # selectInput("selectCountry","Change country",
            #choices = mxConfig$countryListChoices,
            #),
          div(id="countryMetrics"),
          h3('Abstract'),
          div(id="countryNarrative")
          ),
        div(class="col-md-6 col-xs-12 text-left",
          h3("RGI"),
          #
          # Ressource gouvernance index 
          #
          p("The Resource Governance Index (RGI) measures the quality of governance in the oil, gas and mining sector of 58 countries. From highly ranked countries like Norway, the United Kingdom and Brazil to low ranking countries like Qatar, Turkmenistan and Myanmar, the Index identifies critical achievements and challenges in natural resource governance."),
          tags$canvas(id="testChart",width="100",height="70",style="width:100%;height:auto"),
          div(class="col-md-12",
            h5("Labels"), 
            tags$ul(
              tags$li(tags$span("Comp. = Composite")),
              tags$li(tags$span("Enab. = Enabling environnment")),
              tags$li(tags$span("Inst. = Institutional and legal setting")),
              tags$li(tags$span("Repo. = Reporting practices")),
              tags$li(tags$span("Safe. = Safeguards and quality controls"))
              ),
            p("Data source:", tags$a(href="http://www.resourcegovernance.org/","RGI"))
            ),
          #
          # World bank developemnt indicators
          #
          h3("World Develpment indicators"),
          p("World Development Indicators (WDI) is the primary World Bank collection of development indicators, compiled from officially recognized international sources. It presents the most current and accurate global development data available, and includes national, regional and global estimates."),
          selectizeInput(
            inputId="selectIndicator",
            label="Select an indicator",
            choices=mxConfig$wdiIndicators,
            selected="NY.GDP.PCAP.KD"
            ),
          dygraphOutput("dyGraphWdi"),
          div(id="wdiMsg"),
          p("Data source:", tags$a(href="http://databank.worldbank.org/","WDI"))
          )
        )
      )
    )
  )


