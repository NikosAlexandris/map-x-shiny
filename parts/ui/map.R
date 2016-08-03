#                             
#  _ __ ___   __ _ _ __   __  __
# | '_ ` _ \ / _` | '_ \  \ \/ /
# | | | | | | (_| | |_) |  >  < 
# |_| |_| |_|\__,_| .__/  /_/\_\
#                 | |           
#                 |_|           


#
# UI UPLOAD LAYER
#
uiMapCreatorLayer <- tagList(
  tags$div(id="mxUiMapCreatorView",class="",
    selectInput(
      inputId="selNewLayerClass",
      label="Layer class",
      choice=mxConfig$class
      ),
    selectInput("selNewLayerVisibility",
      label= "Layer visibility",
      choices=mxConfig$noData
      ),
    conditionalPanel(condition=sprintf(
        "(input.selNewLayerClass != '%1$s' && input.selNewLayerVisibility != '%1$s')",
        mxConfig$noData
        ),
      tagList(
        textInput("txtNewLayerTags","Additional tags","default"),
        tags$textarea(
          id="txtNewLayerMeta",
          rows=10,
          cols=30,
          placeholder="Sources...",
          spellcheck="false",
          mxConfig$bibDefault
          ),
        mxFileInput("fileNewLayer",
          label="Choose a file (geojson)",
          multiple=FALSE,
          fileAccept=mxConfig$inputDataExt$vector$GeoJSON
          ),
        div(id="outLayerFileMsg"),
        div(id="outNewLayerErrors"),                
        div(id="outNewLayerNameValidation")
        )
      )
    )
  )
#
# UI CREATE NEW VIEW
#
uiMapCreatorView <- tagList(
  tags$div(id="mxUiMapCreatorLayer",class="",
    selectInput("selLayer","Layer",choices=mxConfig$noData),
    selectInput("selNewViewVisibility",
      label= "View visibility",
      choices=mxConfig$noData
      ),
    conditionalPanel(condition=sprintf(
        "input.selLayer != '%1$s' && input.selNewViewVisibility != '%1$s'",
        mxConfig$noData
        ),
      tagList(
        textInput("mapViewTitle","Title",mxConfig$noData),
        conditionalPanel(condition=sprintf("input.mapViewTitle != '%s'",mxConfig$noData),
          selectInput("selColumnVar","Variable to display",choices=mxConfig$noData),
          conditionalPanel(condition=sprintf("input.selColumnVar != '%s'",mxConfig$noData),
            textInput("txtVarUnit","Suffix for labels"),
            selectInput("selPalette","Colors",choices=""),
            selectInput("selColumnVarToKeep","Variable(s) to keep",choices="",multiple=T),
            numericInput("selOpacity","Opacity",min=0,max=1,value=0.6,step=0.1),
            numericInput("selSize","Size point / line",min=0,max=100,value=5,step=0.1),
            selectInput("mapViewClass","View class",choices=mxConfig$class),
            tags$textarea(
              id="txtViewDescription",
              rows=10,
              cols=30,
              placeholder="Description...",
              spellcheck="false"
              ),
            actionButton("btnViewCreatorSave","Save view")
            )
          )
        )
      )
    )
  )

#
# TOOL BASE MAP
#
uiMapConfigBaseMap = tagList(
  selectInput(
    "selectConfigBaseMap",
    "Select a satellite imagery source",
    choices=list(
      `Here satellite`="heresat",
      `MapBox satellite`="mapboxsat",
      `MapBox satellite live`="mapboxsatlive"
      )
    )
  )
#
# TOOL  WMS EXTERNAL LAYER
#
uiMapConfigWms = tagList(
  selectInput("selectWmsServer",
    "Select a predefined WMS server",
    choices=mxConfig$wmsSources
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
#
# TOOL MAP OVERLAP ANALYSIS
#
uiMapOverlap <- tagList(
    selectInput("selectOverlapA","Map to query",choices=mxConfig$noData),
    selectInput("selectOverlapAVar","Variable to keep",
      choices="",
      multiple=TRUE
      ),
    selectInput("selectOverlapB","Zone",choices=mxConfig$noData),
    actionButton("btnAnalysisRemoveLayer",icon("times")),
    actionButton("btnAnalysisOverlaps",icon("play")),
    span(id="txtAnalysisOverlaps","")
  )
#
# TOOL POLYGON OF INTEREST
#
uiMapPolygonOfInterest <- tagList(
  tags$p("Use the toolbar to select an area of interest, then fill the form.")
  )

#
# TOOL STORY CREATOR
#
uiStoryNew <- tagList(
  textInput("txtStoryName","Add new story title"), 
    tagList(
      tags$label("Validation"),
      div(id="validateNewStoryName")
      ),
    actionButton("btnSaveNewStory",
      label=icon("save")
      ) 
  )
#
# TOOLBOX
#
uiMapToolbox <- tagList(
  tags$section(id="mxModeToolBox",class="mx-panel-mode mx-hide",
    div(class="row",
      div(class="col-lg-12", 
        mxAccordionGroup(id="mxToolBox",
          itemList=list(
            uiMapOverlap=list(
              class="mx-allow-overlap",
              title="Overlap analysis",
              content= uiMapOverlap
              ),
            uiMapPolygonOfInterest=list(
              class="mx-allow-polygon-of-interest",
              title="Polygon of interest",
              content=uiMapPolygonOfInterest,
              onHide='Shiny.onInputChange("mxPoiDrawShow",false)',
              onShow='Shiny.onInputChange("mxPoiDrawShow",true)'
              ),
            uiMapConfigWms = list(
              class = "mx-allow-wms",
              title = "External WMS layer",
              content = uiMapConfigWms
              ),
            uiMapConfigBaseMap=list(
              class = "mx-allow-basemap",
              title="Satellite imagery",
              content = uiMapConfigBaseMap
              ),
            data=list(
              class="mx-allow-upload",
              title="Upload New Data",
              content=tagList(
                uiMapCreatorLayer
                )
              ),
            style=list(
              class="mx-allow-creator",
              title="Create a view",
              content=tagList(
                uiMapCreatorView
                )
              ),
            newStory=list(
              class="mx-allow-story-creator",
              title="Create a story map",
              content = uiStoryNew
              )
            )
          )
        )
      )
    )
  )

#
# SECTION EXPLORER 
#
uiMapList <- tagList(
  tags$section(id="mxModeExplorer",class="mx-panel-mode",
    div(class="row",
      div(class="col-lg-12",
        # created in parts/server/views.R
        uiOutput('checkInputViewsContainer')
        )
      )
    )
  )



#
# STORY SELECTOR
#
uiMapStorySelector <- tagList(
  selectizeInput(
    inputId="selectStoryId", 
    label="", 
    choices ="",
    options = list(
      placeholder = 'Select a story'
      )
    )
  )

  #
  # STORY MAP READER
  #

uiMapStoryReader <- tagList(
  tags$section(id="mxModeStoryMap",class="mx-panel-mode mx-hide",
    conditionalPanel(condition=sprintf(
        "input.selectStoryId.length>0 &&
        input.selectStoryId != ''
      ",mxConfig$noData),  
      div(id="mxStoryText")
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
    #
    # UI BUTTONS
    # 
    tags$li(
      tags$button(
        id="btnToggleMapLeft",
        mx_set_lang="title.mapLeft.hide",
        onClick="classToggle('mapLeftPanel')",
        class="btn-icon btn-square",
        icon("bars")
        )
      ),
    #
    # Explorer : switch panel and set title
    #
    tags$li(
      tags$button(
        id="btnModeExplorer",
        mx_set_lang="title.mapLeft.explorer",
        onClick="enablePanelMode('mxModeExplorer','Views Explorer')",
        class="btn-icon btn-square",
        icon("map-o")
        )
      ),
    #
    # Story reader : switch panel and set title
    #
    tags$li(
      tags$button(
        id="btnModeStoryReader",
        mx_set_lang="title.mapLeft.storyReader",
        onClick="enablePanelMode('mxModeStoryMap','Story Map Reader')",
        class="btn-icon btn-square",
        icon("newspaper-o")
        )
      ),
    #
    # Toolbox : switch panel and set title
    #
    tags$li(
      tags$button(
        id="btnModeToolBox",
        mx_set_lang="title.mapLeft.toolbox",
        onClick="enablePanelMode('mxModeToolBox','Toolbox')",
        class="btn-icon btn-square",
        icon("cogs")
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
      div(id="infoBox",class="info-box mx-hide",
        div(class="info-box-container",      
          uiOutput("infoBoxContent",class="info-box-content")
          )
        ),
      # LEFT PANEL
      #
      #div(id="map-left-container",class="",
      #
      # TOOLBOX      
      #      
      div(class="mx-dropdown-content map-tool-box-items mx-hide",
        id="mapToolsMenu",
        uiLeftNav
        ),
      #
      # MENU 
      #
      div(id="mapLeftPanel",class="map-left-panel col-xs-7 col-sm-6 col-md-5 col-lg-4",
        #
        # HEADER
        #
        div(id="mapLeftPanelHead",  
          #
          # MENU
          #
          tags$div(class="mx-dropdown map-tool-box-container",
            tags$div(
              onclick="classToggle('mapToolsMenu')",
              id='btnMapTools',
              class="mx-btn-link mx-btn-link-white",
              tags$span(class='fa fa-bars')
              )
            ),
          tags$div(class="mx-dropdown map-tool-box-container mx-hide mx-mode-story-reader", style="float:right",
            tags$div(
              onclick="classToggle('mxStorySelectorBox')",
              id='btnMapTools',
              class="mx-btn-link mx-btn-link-white",
              tags$span(class='fa fa-search')
              )
            ),
          tags$div(class="map-tool-box-container mx-hide mx-allow-story-edit", style="float:right",
            actionLink(
              inputId="btnStoryEdit",
              class="mx-btn-link mx-btn-link-white",
              tags$span(class="fa fa-pencil")
              )
            ),
          tags$div(class="map-tool-box-container mx-hide mx-allow-story-edit", style="float:right",
            actionLink(
              inputId="btnStoryDelete",
              class="mx-btn-link mx-btn-link-white",
              tags$span(class="fa fa-trash-o")
              )
            ),

          
          #
          # TITLE
          #
          tags$div(
            span(id="titlePanelMode","Views explorer")
            ),
          #
          # STORY SELECTOR
          #
          div(
            id="mxStorySelectorBox",class="mx-hide mx-mode-story-reader",
            uiMapStorySelector
            )
          ),
        #
        # CONTENT
        #
        div(class="map-left-content",
          div(id="mxStoryLimitTrigger",class="mx-mode-story-reader mx-hide"),
          div(class="no-scrollbar-container no-scrollbar-container-border",
            div(class="no-scrollbar-content",id="mapLeftScroll", 
              uiMapList,
              uiMapToolbox,
              uiMapStoryReader
              )
            )
          )
        )
      #)
      )
    )


