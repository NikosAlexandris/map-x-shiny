#                             
#  _ __ ___   __ _ _ __   __  __
# | '_ ` _ \ / _` | '_ \  \ \/ /
# | | | | | | (_| | |_) |  >  < 
# |_| |_| |_|\__,_| .__/  /_/\_\
#                 | |           
#                 |_|           
# map content

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


uiMapCreator <- tagList(
  #
  # MAP CREATOR
  #
  tags$section(id="sectionMapcreator",class="section-map-creator mx-mode-creator container-fluid mx-hide",
    mxAccordionGroup(id="mapCreator",
      itemList=list(
        "data"=list(
          "title"="Upload new data",
          content=tagList(
            uiMapCreatorLayer
            )
          ),
        "style"=list(
          "title"="Create a view",
          content=tagList(
            uiMapCreatorView
            )
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



uiMapConfigBaseMap = tagList(
  selectInput(
    "selectConfigBaseMap",
    "Select a satellite imagery source",
    choices=list(
      mxConfig$noLayer,
      `MapBox satellite`="mapboxsat",
      `MapBox satellite live`="mapboxsatlive",
      `Here satellite`="heresat"
      )
    )
  )

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



#uiMapConfig <- tagList(
  #
  # MAP config
  #
 # tags$section(
    #id="sectionMapConfig",
    #class="section-map-creator mx-mode-config container-fluid mx-hide",
    #tagList(
      #hr(),
      #h3("Base map"),
      #uiMapConfigBaseMap,
      #hr(),
      #h3("WMS layer"),
      #uiMapConfigWms
      #)
    #)
  #)

  uiMapConfig <- tagList(
      #
      # Map config
      #
      tags$section(id="sectionMapConfig",class="mx-mode-config mx-hide container-fluid",
        div(class="row",
          div(class="col-lg-12", 
            mxAccordionGroup(id="mapConfig",
              itemList=list(
                "uiMapConfigWms" = list(
                  "title" = "External WMS layer",
                  content = uiMapConfigWms
                  ),
                "uiMapConfigBaseMap"=list(
                  "title"="Base map",
                  content = uiMapConfigBaseMap
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
            mxAccordionGroup(id="mapAnalysis",show=1,
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


    #uiStorySelect <- tagList(
      ##
      ## Story selection
      ##
      ##selectInput("selectStoryId","Select a story",choices="")
      #)

    #uiStoryNew <- tagList(
      ##
      ## New story crator
      ##
      #textInput("txtStoryName","Add new story title"), 
      #tags$label("Validation"),
      #div(id="validateNewStoryName"),
      #actionButton("btnSaveNewStory",label=icon("save"))  
      #)

    #uiStoryEditor <- tagList(
      ##
      ## editor
      ##
      #span("Drag and drop views from the menu; Drag and drop coordinates from the box below :"),
      #div(id="txtLiveCoordinate",draggable=TRUE),
      #selectizeInput(
        #label = "Set the story visibility",
        #inputId="selStoryVisibility",
        #choices=mxConfig$noData
        #),
      #tags$textarea(id="txtStoryMapEditor", rows=12, cols=80, placeholder="Write a story...",spellcheck="false"),
      ##buttons
      #tags$script(
        #"
        #document.getElementById('txtLiveCoordinate')
        #.addEventListener('dragstart',function(e){
          #var coord = document.getElementById('txtLiveCoordinate').innerHTML;
          #e.dataTransfer.setData('text', coord);
          #})"
        #),

      #tags$ul(class="list-inline",
        #tags$li(
          #actionButton(
            #inputId="btnStoryMapEditorUpdate",
            #class="btn-icon btn-square",
            #label=icon("save")
            #)
          #)
        #)
      #)


    #uiStoryCreator<- tagList(
      ##
      ## Tabset with creator components
      ##
 #mxAccordionGroup(id="storyCreator",
      #itemList=list(
        #"edit"=list(
          #"title"="Edit selected story",
          #"condition"=sprintf("input.selectStoryId.length>0 && input.selectStoryId != '%s'",mxConfig$noData),
          #content=tagList(
            #uiStoryEditor
            #)
          #),
        #"new"=list(
          #"title"="Create a story",
          #content=tagList(
            #uiStoryNew
            #)
          #)
        #)
      #)

   ##   div(class="mx-allow-story-edit mx-hide",
        ##tabsetPanel(type="pills",
          ##tabPanel("Edit", uiStoryEditor),
          ##tabPanel("New", uiStoryNew)
          ##)
        ##)
      #)

    #uiMapStoryModal <- tagList(
      ##
      ## STORY MAP MODAL
      ##
      #div(id="storyMapModalHandle",style=" background: rgba(47,47,47,0.8); cursor: move;",
        #tags$ul(class="list-inline",
          #tags$li(
            #div(class="btn-close",
              #tags$i(class="fa fa-times"),
              #onclick="$('#storyMapModal').addClass('mx-hide')"
              #)
            #)
          #)
        #),
      #div(class="no-scrollbar-container",
        #div(class="no-scrollbar-content",
          #div(style="width: 100%;padding: 10px;",
            #uiStorySelect,
            #uiStoryCreator
            #)
          #)
        #)
      #)




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






    uiMapStoryReader <- tagList(
      #
      # STORY MAP PREVIEW / READER
      #

      tags$section(id="sectionStoryMapReader",class="mx-mode-story-reader mx-hide",
        conditionalPanel(condition="input.selectStoryId.length>0",  
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
          mx_set_lang="title.mapLeft.hide",
          onClick="classToggle('mapLeftPanel')",
          class="btn-icon btn-square",
          icon("bars")
          )
        ),
      #
      # PANEL BUTTON
      #
      tags$li(
        actionButton('btnViewsExplorer',
          mx_set_lang="title.mapLeft.explorer",
          class="btn-icon btn-square",
          label=icon("globe")
          )
        ),

      tags$li(
        actionButton('btnStoryReader',
          mx_set_lang="title.mapLeft.storyReader",
          class="btn-icon btn-square mx-hide mx-allow-story-reader",
          label=icon("newspaper-o")
          )
        ),
      tags$li(
        actionButton('btnViewsConfig',
          mx_set_lang="title.mapLeft.config",
          class="btn-icon btn-square",
          label=icon("sliders")
          )
        ),
      tags$li(
        actionButton('btnViewsToolbox',
          mx_set_lang="title.mapLeft.toolbox",
          class="btn-icon btn-square",
          label=icon("cubes")
          )
        ),
      tags$li(
        actionButton('btnDraw',
          mx_set_lang="title.mapLeft.draw",
          class="btn-icon btn-square",
          label=icon("cloud-download")
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
        div(class="mx-mode-story-reader mx-hide",
          actionButton(
            inputId="btnStoryCreator",
            label=icon("pencil-square-o"),
            mx_set_lang="title.mapLeft.storyEdit",
            class="btn btn-icon btn-square mx-mode-story-edits mx-hide"
            )
#        tags$button(id='btnStoryCreator',
          #mx_set_lang="title.mapLeft.storyEdit",
          #onClick="classToggle('storyMapModal')",
          #class="btn btn-icon btn-square mx-mode-story-edits mx-hide",
          #icon("pencil-square-o")
          #)
        )
      ),  
    tags$li(
      actionButton(inputId="btnZoomToLayer",
        class="btn-icon btn-square mx-mode-creator mx-hide",
        label=icon("binoculars")
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
      ##
      ## UI STORY MODAL
      ##
      #div(id="storyMapModal",style="position:fixed",class="mx-story-modal mx-hide",
        #uiMapStoryModal
        #),
      ##
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
            tags$div(class="map-tool-box-container mx-hide mx-allow-story-creator", style="float:right",
              actionLink(
                inputId="btnStoryNew",
                class="mx-btn-link mx-btn-link-white",
                tags$span(class="fa fa-plus")
                )
              ),
            tags$div(class="map-tool-box-container mx-hide mx-allow-story-edit", style="float:right",
              actionLink(
                inputId="btnStoryEdit",
                class="mx-btn-link mx-btn-link-white",
                tags$span(class="fa fa-pencil")
                )
              ),
             tags$div(class="map-tool-box-container mx-hide mx-allow-creator", style="float:right",
              actionLink(
                inputId="btnViewsCreator",
                class="mx-btn-link mx-btn-link-white",
                tags$span(class="fa fa-plus")
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
                uiMapCreator,
                uiMapToolbox,
                uiMapConfig,
                uiMapStoryReader
                )
              )
            )
          )
        #)
      )
    )


