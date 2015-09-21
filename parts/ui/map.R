#
# MAP-CONTENT
#
uiMapCreator <-tagList(
  #
  # MAP CREATOR
  #
  tags$section(id="sectionMapcreator",class="container-fluid",
    div(class="row",
      div(class="col-lg-12",
        mxAccordionGroup(id="mapCreator",
          itemList=list(
            "data"=list("title"="Data upload",content=tagList(
                selectInput("selNewLayerClass","Select layer class",choice=mxConfig$class),
                selectInput("selNewLayerSubClass","Select layer subclass",choice=""),
                fluidRow(
                  column(width=6,
                    selectInput("selNewLayerStartYear","Layer min year",choices=mxConfig$yearsAvailable)
                    ),
                  column(width=6,
                    selectInput("selNewLayerStopYear","Layer max year",choices=mxConfig$yearsAvailable)
                    )
                  ),
                hr(),
                uiOutput("newLayerNameValidation"),
                hr(),
                mxFileInput("fileNewLayer",
                  label="Choose a file (geojson)",
                  multiple=FALSE,
                  fileAccept=mxConfig$inputDataExt$vector$GeoJSON
                  )
                )
              ),
            "style"=list("title"="Style settings",content=tagList(
                selectInput("selLayer","Select a vector tiles layer",choices=""),
                selectInput("selColumnVar","Select a variable",choices=""),
                selectInput("selPalette","Select a palette",choices=""),
                numericInput("selOpacity","Opacity",min=0,max=1,value=0.6,step=0.1),
                numericInput("selSize","Size point / line",min=0,max=100,value=5,step=0.1),
                ##checkboxInput("checkBoxInversePalette","Inverse palette"),
                checkboxInput("checkBoxUseDate","Use a date column"),
                conditionalPanel(condition="input.checkBoxUseDate == true",
                  selectInput("selColumnDate","Select date column",choices="")
                  ))),
            "filter"=list("title"="Filter variable",content=tagList(
                textInput("txtFilter","Set a perl regex")
                )),
            "storyMap"=list("title"="Story map settings",content=tagList(
                textOutput("txtLiveCoordinate"),
                selectInput("selectBaseMap","Select a base map",choices=mxConfig$tileProviders),
                checkboxInput("checkBoxUseBounds","Store map position and zoom"),
                checkboxInput("checkBoxHideLabels","Hide labels"),
                checkboxInput("checkBoxHideLegends","Hide legend")
                )), 
            "meta"=list("title"="Metadata",content=tagList(
                textInput("mapViewTitle","Map view title","[Map view title]"),
                selectInput("mapViewClass","Map view class",choices=mxConfig$class),
                dateRangeInput("mapViewDateRange",
                  label = "Set a date range for this layer",
                  start = Sys.Date(), end = Sys.Date(),
                  min = "01-01-1970", max = "01-01-2050",
                  separator = " - ", format = "dd/mm/yyyy",
                  startview = "year", language = "en", weekstart = 1
                  ),
                tags$b("Description"),
                aceEditor("mapViewDesc", mode="markdown", value="Enter description",height="100px")

                )
              )
            )
          ),
          div(class="shiny-input-container-inline shiny-flow-layout",
            actionButton("btnMapCreatorSave",class="btn-icon",label=icon("floppy-o")),
            actionButton("btnZoomToLayer",class="btn-icon",label=icon("binoculars")),
            actionButton('btnViewsRefresh',class="btn-icon",label=icon("refresh")),
            tags$h4(textOutput("txtValidationCreator"))
            ) 
          )
        )
      )
    )

  uiMapList <- tagList(
    #
    # MAP 
    #
    tags$section(id="sectionMapList",class="container-fluid",
      div(class="row",
        div(class="col-lg-12",
          uiOutput('checkInputViewsContainer')
          )
        )
      )
    )


  uiMapConfig <- tagList(
    #
    # MAP CONFIG
    #
    tags$section(id="sectionMapConfig",class="container-fluid",
      div(class="row",
        div(class="col-lg-12", 
          h4('Opacity'),
          sliderInput('sliderConfigOpacity','Change layers opacity',min=0,max=1,step=0.1,value=0.5),
          h4('Set base map'),
          selectInput('selectConfigBaseMap','Replace base map',choices=mxConfig$tileProviders),
          h4('Add wms'),
          textInput("txtConfigAddWms","Paste WMS URL with {z}/{x}/{y} template")
          )
        )
      )
    )


  #
  # MAP SECTION
  #

  tags$section(id="sectionMap",
#    conditionalPanel(condition="output.uiDisplayMap==true",
      div(class="map-wrapper col-xs-12",
        #
        # ERROR PANNEL
        #
        uiOutput('panelAlert'),
        #
        # LEAFLET PART
        #
        leafletOutput("mapxMap",width="100%",height="100%"),
        div(id="info-box",
          div(id="info-box-container",
            h4("Object information"),
            div(id="info-box-content")
            )
          ),
        #
        # MAP LEFT
        #
        div(id="map-left",class="scrollable",
          div(class="map-text scrollable",
            h2(textOutput("titlePanelMode")),
            div(class="row",
              div(class="map-text-left",
                conditionalPanel(condition="mxPanelMode.mode == 'mapViewsExplorer'",
                  uiMapList
                  ),
                conditionalPanel(condition="mxPanelMode.mode == 'mapViewsCreator'",
                  uiMapCreator
                  ),
                conditionalPanel(condition="mxPanelMode.mode == 'mapViewsConfig'",
                  uiMapConfig
                  ) 
                ),
              div(class="map-text-nav",
                tags$ul(class="nav",
                  tags$li(tags$button(id="btnStopMapScroll",class="btn-icon",icon("unlock"))),
                  tags$li(tags$button(id='btnViewsCollapse', class="btn-icon",icon("angle-double-left"))),
                  tags$li(actionButton('btnViewsExplorer',class="btn-icon",label=icon("map-o"))),
                  tags$li(actionButton('btnViewsCreator',class="btn-icon",label=icon("plus"))),
                  tags$li(tags$button(id='btnInfoClick',class="btn-icon",icon("info"))),
                  tags$li(actionButton('btnViewsConfig',class="btn-icon",label=icon("wrench")))
                  )
                )
              )
            ) 
          )
        )
     # )
    )



