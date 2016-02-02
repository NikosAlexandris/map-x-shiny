#                             
#  _ __ ___   __ _ _ __   __  __
# | '_ ` _ \ / _` | '_ \  \ \/ /
# | | | | | | (_| | |_) |  >  < 
# |_| |_| |_|\__,_| .__/  /_/\_\
#                 | |           
#                 |_|           
# map content

uiMapCreator <- tagList(
  #
  # MAP CREATOR
  #
  tags$section(id="sectionMapcreator",class="section-map-creator mx-mode-creator container-fluid mx-hide",
    div(class="row",
      div(
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
                div(id="newLayerNameValidation"),
                hr(),
                mxFileInput("fileNewLayer",
                  label="Choose a file (geojson)",
                  multiple=FALSE,
                  fileAccept=mxConfig$inputDataExt$vector$GeoJSON
                  )
                )
              ),
            "style"=list("title"="Style settings",content=tagList(
                textInput("mapViewTitle","Map view title",mxConfig$noTitle),
                selectInput("selLayer","Select a vector tiles layer",choices=""),
                selectInput("selColumnVar","Select a variable to display",choices=""),
                textInput("txtVarUnit","Unit suffixe"),
                selectInput("selPalette","Select a palette",choices=""),
                selectInput("selColumnVarToKeep","Select other variables to keep",choices="",multiple=T),
                numericInput("selOpacity","Opacity",min=0,max=1,value=0.6,step=0.1),
                numericInput("selSize","Size point / line",min=0,max=100,value=5,step=0.1),
                selectInput("mapViewClass","Map view class",choices=mxConfig$class),
                dateRangeInput("mapViewDateRange",
                  label = "Set a date range for this layer",
                  start = Sys.Date(), end = Sys.Date(),
                  min = mxConfig$minDate, max = mxConfig$maxDate,
                  separator = " - ", format = "yyyy/mm/dd",
                  startview = "year", language = "en", weekstart = 1
                  ),
                tags$b("Description"),
                aceEditor("txtViewDescription", mode="markdown", value="Enter description",height="100px"),
                ##checkboxInput("checkBoxInversePalette","Inverse palette"),
                checkboxInput("checkBoxUseDate","Use a date column"),
                conditionalPanel(condition="input.checkBoxUseDate == true",
                  selectInput("selColumnDate","Select date column",choices="")
                  ))),
            "storyMap"=list("title"="Story map settings",content=tagList(
                selectInput("selectBaseMap","Select a base map",choices=mxConfig$tileProviders),
                checkboxInput("checkBoxUseBounds","Store map position and zoom"),
                checkboxInput("checkBoxHideLabels","Hide labels"),
                checkboxInput("checkBoxHideLegends","Hide legend")
                )) 
            )
          ),
        div(class="shiny-input-container-inline shiny-flow-layout",
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
  tags$section(id="sectionMapList",class="mx-mode-explorer container-fluid",
    div(class="row",
      div(class="col-lg-12",
        # created in parts/server/views.R
        uiOutput('checkInputViewsContainer')
        )
      )
    )
  )


uiMapConfig <- tagList(
  #
  # MAP CONFIG
  #
  tags$section(id="sectionMapConfig",class="mx-mode-config mx-hide container-fluid",
    div(class="row",
      div(class="col-lg-12", 
        mxAccordionGroup(id="mapConfig",show=1,
          itemList=list(
            "baseMap"=list("title"="Additional maps",content=tagList(
                h4('Set base map'),
                selectInput('selectConfigBaseMap','Replace base map',choices=mxConfig$tileProviders),
                tags$ul(class="list-inline banner-social-buttons",
                  tags$li(actionButton("btnRemoveBaseMap",icon("times")))
                  ),
                h4('Add wms'),
                selectInput("selectWmsServer","Select a predefined WMS server",choices=list(
                    "forestCover"="http://50.18.182.188:6080/arcgis/services/ForestCover_lossyear/ImageServer/WMSServer",
                    "columbia.edu"="http://sedac.ciesin.columbia.edu/geoserver/wms",
                    "preview.grid.unep.ch"="http://preview.grid.unep.ch:8080/geoserver/wms",
                    "sampleserver6.arcgisonline.com"="http://sampleserver6.arcgisonline.com/arcgis/services/911CallsHotspot/MapServer/WMSServer",
                    "nowcoast.noaa.gov"="http://nowcoast.noaa.gov/arcgis/services/nowcoast/analysis_meteohydro_sfc_qpe_time/MapServer/WmsServer"
                    )
                  ),
                textInput("txtWmsServer","Edit WMS server"),
                tags$ul(class="list-inline banner-social-buttons",
                  tags$li(actionButton("btnValidateWms",icon("refresh")))
                  ),
                textOutput("msgWmsServer"),
                selectInput("selectWmsLayer","Select available layer",choices=""),
                tags$ul(class="list-inline banner-social-buttons",
                  tags$li(actionButton("btnRemoveWms",icon("times")))
                  )
                )
              )
            )
          )
        )
      )
    )
  )


uiMapToolbox <- tagList(
  #
  # UI ANALYTICS
  #
  tags$section(id="sectionMapAnalysis",class="mx-mode-toolbox mx-hide container-fluid",
    div(class="row",
      div(class="col-lg-12", 
        mxAccordionGroup(id="mapConfig",show=1,
          itemList=list(
            "analysis"=list("title"="Analysis",content=tagList(
                selectInput("selectAnalysis","Select an analysis",
                  choices=list("Overlaps"="overlaps")
                  ),
                uiOutput("uiAnalysis"),
                actionButton("btnAnalysisRemoveLayer",icon("times"))
                )
              )
            )
          )
        )
      )
    )
  )




#
# STORY MAP
#


uiStorySelect <- tagList(
  #
  # Story selection
  #
  #selectInput("selectStoryId","Select a story",choices="")
  )

uiStoryNew <- tagList(
  #
  # New story crator
  #
  textInput("txtStoryName","Add new story title"), 
  tags$label("Validation"),
  div(id="validateNewStoryName"),
  actionButton("btnSaveNewStory",label=icon("save"))  
  )

uiStoryEditor <- tagList(
  #
  # editor
  #
  tags$textarea(id="txtStoryMap", rows=12, cols=80, placeholder="Write a story...",spellcheck="false"),
  #buttons
  span("Drag and drop views from the menu; Drag and drop coordinates from the box below :"),
  div(id="txtLiveCoordinate",draggable=TRUE),
 tags$script(
            "
            document.getElementById('txtLiveCoordinate')
            .addEventListener('dragstart',function(e){
              var coord = document.getElementById('txtLiveCoordinate').innerHTML;
              e.dataTransfer.setData('text', coord);
        })"
            ),

  tags$ul(class="list-inline",
    tags$li(
      actionButton(
        inputId="btnStoryMapEditorUpdate",
        class="btn-icon",
        label=icon("save")
        )
      )
    )
  )


uiStoryCreator<- tagList(
 #
    # Tabset with creator components
    #
  div(class="mx-allow-story-edit mx-hide",
    tabsetPanel(type="pills",
      tabPanel("Edit", uiStoryEditor),
      tabPanel("New", uiStoryNew)
      )
    )
  )

uiMapStoryModal <- tagList(
  #
  # STORY MAP MODAL
  #
  div(id="storyMapModalHandle",style=" background: rgba(47,47,47,0.8); cursor: move;",
    tags$ul(class="list-inline",
      tags$li(
        div(class="btn-close",
          tags$i(class="fa fa-times"),
          onclick="$('#storyMapModal').addClass('mx-hide')"
          )
        )
      )
    ),
  div(style="width: 100%;padding: 10px;",
    uiStorySelect,
    uiStoryCreator
    )
  )




uiMapStoryReader <- tagList(
  #
  # STORY MAP PREVIEW / READER
  #
  tags$section(id="sectionStoryMapReader",class="mx-mode-story-reader mx-hide",
    div(class="no-scroll-container",
    div(id="mxStoryContainer",class="no-scroll-content",  
      div(id="mxStoryLimitTrigger"),
      div(id="mxStoryText")
      )
    )
    )
  )

#
# MAP SECTION
#


uiLeftNav <- tagList(
  #
  # NAV MENU
  #
#  tags$ul(class="nav",
    #
    # UI BUTTONS
    #
  #  tags$li(
  #    tags$button(
  #      mx_set_lang="title.mapLeft.lock",
  #      #id="btnStopMapScroll",
  #      class="btn-icon btn-stop-map-scroll",
  #      icon("unlock")
  #      )
  #    ),
    tags$li(
      tags$button(
        mx_set_lang="title.mapLeft.hide",
        id='btnViewsCollapse',
        class="btn-icon",
        icon("angle-double-left")
        )
      ),
   # tags$li(
   #   tags$button(
   #     mx_set_lang="title.mapLeft.info",
   #     id='btnInfoClick',
   #     class="btn-icon",
   #     icon("info")
   #     )
   #   ),
  #  tags$li(
  #    hr()
  #    ),
    #
    # PANEL BUTTON
    #
    tags$li(
      actionButton('btnViewsExplorer',
        mx_set_lang="title.mapLeft.explorer",
        class="btn-icon",
        label=icon("globe")
        )
      ),
    tags$li(
      actionButton('btnViewsCreator',
        mx_set_lang="title.mapLeft.creator",
        class="btn-icon mx-hide mx-allow-creator",
        label=icon("plus")
        )
      ), 
    tags$li(
      actionButton('btnStoryReader',
        mx_set_lang="title.mapLeft.storyReader",
        class="btn-icon mx-hide mx-allow-story-reader",
        `data-toggle`="collapse",
        `data-target`="#mxStorySelectorBox",
        label=icon("book")
        ),
      div(id="mxStorySelectorBox",class="collapse",
        selectizeInput("selectStoryId","Select a story",choices="")
        )
      ),
    tags$li(
      actionButton('btnViewsConfig',
        mx_set_lang="title.mapLeft.config",
        class="btn-icon",
        label=icon("sliders")
        )
      ),
    tags$li(
      actionButton('btnViewsToolbox',
        mx_set_lang="title.mapLeft.toolbox",
        class="btn-icon",
        label=icon("cubes")
        )
      ),
 tags$li(
      actionButton('btnDraw',
        mx_set_lang="title.mapLeft.toolbox",
        class="btn-icon",
        label=icon("pencil")
        )
      ),
    #
    # PANEL SPECIFIC BUTTONS
    #
    tags$li(
      hr(class='mx-mode-creator mx-hide')
      ),
    tags$li(
      hr(class='mx-mode-story-reader mx-hide')
      ),
    tags$li(
      actionButton('btnStoryCreator',
        mx_set_lang="title.mapLeft.storyEdit",
        class="btn-icon mx-mode-story-reader mx-hide",
        label=icon("pencil-square-o")
        ),
      singleton(
        tags$script(
          "$('#storyMapModal').draggable({ 
          handle:'#storyMapModalHandle',
          containment: '#sectionMap'
         });
        $('#btnStoryCreator').click(
          function(){
            $id = $('#storyMapModal');
            $id.toggleClass('mx-hide');
          }
          );"
        )
    )
  ),
    tags$li(
      actionButton("btnMapCreatorSave",
        class="btn-icon mx-mode-creator mx-hide",
        label=icon("floppy-o")
        )
      ),
    tags$li(
      actionButton("btnZoomToLayer",
        class="btn-icon mx-mode-creator mx-hide",
        label=icon("binoculars")
        )
      ),
    tags$li(
      actionButton('btnViewsRefresh',
        class="btn-icon mx-mode-creator mx-hide",
        label=icon("refresh")
        )
      )

    )





tags$section(id="sectionMap",class="mx-section-container mx-hide",
    div(class="map-wrapper col-xs-12", 
      #
      # LEAFLET PART
      #
      leafletOutput("mapxMap",width="100%",height="100%"),
      #
      # INFO BOX
      #
      div(id="info-box",
        div(id="info-box-container",
          uiOutput("info-box-content")
          )
        ),
      #
      # UI STORY MODAL
      #
      div(id="storyMapModal",style="position:fixed",class="mx-story-modal mx-hide",
        uiMapStoryModal
        ),
      #
      # MAP LEFT PANEL
      #
      div(id="map-left-panel", class="map-left-panel-default",
        #
        # TITLE + TOOL BUTTON
        #
        div(id="map-left-panel-head",  

          # button dropdown
          tags$div(
            tags$div(class="mx-dropdown map-tool-box-container",
              tags$div(
                onclick="toggleDropDown('mapToolsMenu')",
                id='btnMapTools',
                class="mx-btn-dropdown",
                tags$span(class='fa fa-bars')
                ),
              tags$ul(class="mx-dropdown-content map-tool-box-items",
                id="mapToolsMenu",
                uiLeftNav
                )
              )
            ),
          # title
          tags$div(
            span(id="titlePanelMode","Views explorer")
            )
          ),
        div(class="map-left-content",
          uiMapList,
          uiMapCreator,
          uiMapToolbox,
          uiMapConfig,
          uiMapStoryReader
          )
        )
      #   div(class="map-left-nav",
      #     )
      )
    )


