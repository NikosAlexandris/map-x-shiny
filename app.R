
#source("fun.R")
source("loadlib.R")
source("fun/helperUi.R")
source("settings/settings.R")
source("config.R")

# NOTE : mvt exemple in Documents/unep_grid/map-x/test/Leaflet.MapboxVectorTile-master/examples/



counter = 0


#
# UI
#

uiNav <- tagList(
  #
  # NAVBAR
  #
  tags$nav(class="navbar navbar-custom navbar-fixed-top",role="navigation",
    div(class="container",
      div(class="navbar-header",
        tags$button(type="button",class="navbar-toggle",`data-toggle`="collapse",`data-target`=".navbar-main-collapse", 
          div(style="font-size;18px;color:white;",icon('bars'))
          ),
        tags$a(class="navbar-brand page-scroll",href="#page-top")
        ), 
      div(class="collapse navbar-collapse navbar-right navbar-main-collapse",
        tags$ul(class="nav navbar-nav",
          tags$li(class="hidden",tags$a(href="#page-top")),
          tags$li(tags$a(class="page-scroll btn btn-circle",href="#sectionTop",tags$i(class="fa fa-home animated"))),
          tags$li(tags$a(class="page-scroll btn btn-circle",href="#sectionCountry",tags$i(class="fa fa-bar-chart animated"))),
          tags$li(tags$a(class="page-scroll btn btn-circle",href="#sectionMap",tags$i(class="fa fa-map-o animated"))),
          tags$li(tags$a(class="page-scroll btn btn-circle",href="#sectionAbout",tags$i(class="fa fa-info animated"))),
          tags$li(tags$a(class="page-scroll btn btn-circle",href="#sectionContact",tags$i(class="fa fa-comment-o animated"))),
          tags$li(class="dropdown",tags$a(id="menuCountry",class="dropdown-toggle",`data-toggle`="dropdown",href="#","Country",tags$span(class="caret")),
              tags$ul(class="dropdown-menu",
                mxConfig$countryListHtml
                )
            )
          ) 
        )
      )
    ) 
  )



uiIntro <- tagList(
  #
  # HEADER
  #
  tags$section(id="sectionTop",class="intro container-fluid",
    div(class="col-md-8 col-md-offset-2",
      h1(class='brand-heading',"MAP-X"),
      hr(),
      tags$p(class="intro-text",
        "Mapping and Assessing the Performance of Extractive Industries in Emerging Economies and Fragile States."
        ),
      hr(),
      tags$p(tags$img(src="img/logo_grid_white_en.svg",style="height:100px;")),
      hr()
      )
    )
  )





uiAbout <- tagList(
  #
  # ABOUT
  #
  tags$section(id="sectionAbout",class="container-fluid",
    div(class="row",
      div(class="col-lg-8 col-lg-offset-2",
        h2("About MAP-X"),
        div(class="col-lg-6 text-left",
          p("The overall aim of UNEP’s Environmental Cooperation for Peacebuilding (ECP) programme is to strengthen the capacity of fragile States, regional organizations, UN entities and civil society to assess and understand the conflict risks and peacebuilding opportunities presented by natural resources and environment in order to formulate more effective response policies and programmes across the spectrum of peace and security operations. To achieve this goal, UNEP/ECP establishes an evidence base of good practices, co-manages a global knowledge platform and community of practice, conducts policy-relevant research with UN and other partners, and helps UN country teams and fragile states apply these policies and practices at the fiield level through technical support and catalytic partnerships.")),
        tags$div(class="col-lg-6 text-left",
          tags$p("Against this background, UNEP/ECP is partnering with the World Bank to explore the feasibility of co-developing an open access geo-mapping platform for extractive industries in fragile states (code named MAP-X). The platform would aim to consolidate all existing resource concession, land use, and risk information into a single open source system in order to provide transparent access to this information by all stakeholders, improve strategic decision making and enhance benefit sharing. As many fragile states contain important reserves of biodiversity, this system could also help improve the identification of environmentally sensitive areas, establish more effective impact mitigation measures, and enhance the environmental management capacity of the g+7 member states. This SSFA with UNIGE will contribute to this feasibility study for the geo-mapping platform.ii")
          )
        )
      )
    )
  )



uiMapCreator <-tagList(
  #
  # MAP CREATOR
  #
  tags$section(id="sectionMapcreator",class="container-fluid",
    div(class="row",
      div(class="col-lg-12",
        mxAccordionGroup(id='mapCreator',
          itemList=list(
            'style'=list('title'='Style settings',content=tagList(
                selectInput("selectBaseMap","Select a base map",choices=mxConfig$tileProviders),
                selectInput("selLayer","Select a vector tiles layer",choices="",selected=""),
                selectInput("selColumn","Select a column",choices="",selected=""),
                selectInput("selPalette","Select a palette",choices=""),
                numericInput("selOpacity","Opacity",min=0,max=1,value=0.6,step=0.1),
                numericInput("selSize","Size",min=0,max=100,value=5,step=0.1)
                )),
            'meta'=list('title'='Meta data',content=tagList(
                textInput("mapViewTitle","Map view title"),
                selectInput("mapClass","Map view class",choices=mxConfig$class),
                dateRangeInput('dateRange',
                  label = "Set a date range for this layer",
                  start = Sys.Date(), end = Sys.Date(),
                  min = "01-01-1970", max = "01-01-2050",
                  separator = " - ", format = "dd/mm/yy",
                  startview = 'year', language = 'en', weekstart = 1
                  ),
                tags$b("Description"),
                aceEditor("code", mode="r", value="",height="100px")

                )
              ),

          'save'=list('title'="Save map",content=p(""))
            )
          )

        )
      )
    )
  )



uiMap <- tagList(
  #
  # MAP-CONTENT
  #
  #tags$section(id="map-content",
  tags$section(id="sectionMap",
    div(class="map-wrapper",
    leafletOutput("mapxMap",width="100%",height="100%"),
      div(id="map-left",
        div(class="map-text",
          h2(textOutput("mapPanelMode")),
          conditionalPanel(condition="mxPanelMode.mode == 'mapViewCreator'",
            uiMapCreator
            )
          ) 
        )
      )
    )
  )


uiCountry <- tagList(
  # 
  # country
  # 
  tags$section(id="sectionCountry",class="container-fluid",
    tagList(
      fluidRow(
        column(width=6,
          fluidRow(
            column(width=4,
              p("")
              ),
            column(width=8,

              h2(textOutput('countryName')),
              h3('Key metrics'),
              selectInput("selectCountry","Change country",choices=""),
              uiOutput("countryMetrics"),
              uiOutput("countryNarrative")
              )
            )
          ),
        column(width=6,
          column(width=8,
          h3('Indicators'),
          tabsetPanel(id="tabIndicators",type="pills",
            tabPanel('Resource Governance Index',    
              p("The Resource Governance Index (RGI) measures the quality of governance in the oil, gas and mining sector of 58 countries. From highly ranked countries like Norway, the United Kingdom and Brazil to low ranking countries like Qatar, Turkmenistan and Myanmar, the Index identifies critical achievements and challenges in natural resource governance."),
              tags$canvas(id="testChart",width="100",height="70",style="width:100%;height:auto"),
              p(class="cite","Data source:", tags$a(href="http://www.resourcegovernance.org/","RGI"))
              ),
            tabPanel("World Develpment indicators",
              p("World Development Indicators (WDI) is the primary World Bank collection of development indicators, compiled from officially recognized international sources. It presents the most current and accurate global development data available, and includes national, regional and global estimates."),
              selectizeInput(
                inputId="selectIndicator",
                label="Select an indicator",
                choices=mxConfig$wdiIndicators,
                selected="NY.GDP.PCAP.KD"
                ),
              dygraphOutput("dyGraphWdi"),
              p(class="cite","Data source:", tags$a(href="http://databank.worldbank.org/","WDI"))
              )
            ),
          column(width=4,p(""))
            )
          )
        )
      )
    )
  )

uiFooter <- tagList(
  #
  # contact
  #
  tags$section(id="sectionContact",class="container-fluid",
    div(class="row",
      div(class="col-lg-8 col-lg-offset-2",
        h2("Contact MAP-X team"),
        p("Feel free to repport any issues and feedback"),
        tags$ul(class="list-inline banner-social-buttons",
          tags$li(
            tags$a(href="https://twitter.com",class="btn btn-default btn-lg",tags$i(class="fa fa-twitter fa-fw"),tags$span(class="network-name","Twitter")),
            tags$a(href="https://github.com/unep-grid",class="btn btn-default btn-lg",tags$i(class="fa fa-github fa-fw"),tags$span(class="network-name","Github")),
            tags$li(actionButton("btnDebug",class="btn-default btn-lg","Show debugger"))
            )
          )
        )
      )
    )
  )


ui <- tagList(
  tags$head(
    #
    # METAS
    #
    tags$meta(`http-equiv`="X-UA-Compatible",content="IE=edge"),
    tags$meta(name="viewport",content="width=device-width, initial-scale=1"),
    tags$meta(name="description", content=""),
    tags$meta(name="author", content=""),
    #
    #STYLE SHEET
    #
    tags$link(href="font-awesome-4.4.0/css/font-awesome.min.css",rel="stylesheet",type="text/css"),
    tags$link(href="theme/grayscale/bootstrap.min.css",rel="stylesheet",type="text/css"),
    #tags$link(href="theme/grayscale/grayscale.css",rel="stylesheet",type="text/css"),
    tags$link(href="mapx/mapx.css",rel="stylesheet",type="text/css")
    ),
  tags$body(id="page-top",`data-spy`="scroll",`data-target`=".navbar-fixed-top", `data-offset`="0",
    # 
    # SECTIONS
    #
    uiNav,
    uiIntro,
    uiCountry,
    uiMap,
    uiAbout,
    uiFooter
    ),
  #
  # Scripts
  #
  tags$head(
    tags$script(src="chartjs/Chart.min.js"),
    tags$script(src="mapx/mapx.js"),
    tags$script(src="mapx/mapxChartJsConf.js"),
    tags$script(src="theme/grayscale/grayscale.js"),
    tags$script(src="theme/grayscale/jquery.easing.min.js"),
    tags$script(src="bootstrap/js/bootstrap.min.js")
    )
  )





  #
  # Server
  #
  server <- function(input, output, session) {


    #
    # TEst output
    #

output$mapPanelMode = renderText({mxSetMapPanelMode(mode='mapViewCreator',title='Map view creator')})

    #
    # CONTROL URL PARSING
    #


    # set reactive values

    mxSession <- reactiveValues()
    observe({
      query <- parseQueryString(session$clientData$url_search)
      if(isTRUE(query$country %in% mxConfig$countryListChoices$pending || query$country %in% mxConfig$countryListChoices$potential)){
        sel = query$country
      }else{
        sel = NULL
      }
      updateSelectInput(session,'selectCountry',selected=sel,choices=mxConfig$countryListChoices)
    })


   observe({
     selCountry = input$selectCountry
     if(!noDataCheck(selCountry)){
       mxSession$selectCountry = selCountry
     }
   })





    #
    # Update ui with country data
    #

    observe({
      # mxCatch("Get country indicators",{
      cSelect <- mxSession$selectCountry
      if(!noDataCheck(cSelect)){
        if(cSelect %in% names(mxData$countryInfo)){
          print(cSelect)
          cInfo  <- mxData$countryInfo[[cSelect]]
          # extract country metrics
          countryMetrics <-  tags$ul(class="list-group",
            tags$li(class="list-group-item",tags$b("GDP :"),tags$span(class="badge",cInfo[['gdp']])),
            tags$li(class="list-group-item",tags$b("HDI :"),tags$span(class="badge",cInfo[['hdi']])),
            tags$li(class="list-group-item",tags$b("Status EITI:"),tags$span(class="badge",cInfo[['eiti_status']])),
            tags$li(class="list-group-item",tags$b("Gvt. revenues:"),tags$span(class="badge",cInfo[['gvt_revenues']])),
            tags$li(class="list-group-item",tags$b("Comp. payments"),tags$span(class="badge",cInfo[['comp_payment']]))
            )
          countryNarrative <-
            div(style="background:rgba(70,70,70,0.1)",
              HTML(cInfo[['story']])
              )
        }else{
          countryMetrics <- tags$b("[ No metrics available yet ]")
          countryNarrative <- tags$b("[ No narratives yet ]")
        }


        # set countryname with standard code
        countryName <- countrycode(cSelect,"iso3c","country.name")

        # update graphs
        if(! noDataCheck(cSelect)){
          dat = mxData$rgi_score_2013
          dat = dat[dat$iso3 == cSelect,]
          rgiNames = names(dat)
          labels = rgiNames[
            ! rgiNames %in% c(
              'iso3','Rank','Country','Resource','measured','Resource measured'
              )
            ]
          values = as.vector(t(dat[labels]))
          mxUpdateChartRadar(
            id='testChart',
            main="RGI 2013 score",
            labels= labels,
            values=values
            ) 
        }

        # output ui and text

        output$countryName <- renderText(countryName)
        output$countryMetrics <- renderUI(countryMetrics)
        output$countryNarrative <- renderUI(countryNarrative)
        #})
      }
    })



    mxUpdatePanel(
      panelId="panelMain",
      title="MAP-X",
      subtitle="This is the technical proof of concept version of map-x",
      background=F,
      hideCloseButton=T,
      draggable=F,
      style="top:0px; left:0px;bottom=0px; width:500px; height:100%; height:100vh; z-index:10; opacity:0.94",
      html=list(
        div(style="zoom:1",
          selectizeInput(
            inputId="selectCountry",
            label="Select a country",
            choices=mxConfig$countryList),
          tabsetPanel(type="pills",
            tabPanel(p('Narratives'),
              h4('Ressource gouvernance index'),
              p('Hallo'),
              tags$canvas(id="testChart",width="500px",height="50%"),
              p('test')
              ),
            tabPanel(p("World bank indicators"),tagList(
                selectizeInput(
                  inputId="selectIndicator",
                  label="Select an indicator",
                  choices=mxConfig$wdiIndicators,
                  selected="NY.GDP.PCAP.KD"
                  ),
                dygraphOutput("dyGraphWdi")
                ))
            )
          )
        ),
      listActionButton=list( 
        actionButton("btnDebug","debug"),
        actionButton("btnShowMapCreator","map creator")
        )
      )

    observeEvent(input$btnShowMapCreator,{ 
      mxTogglePanel(id="panelModal")
      })

#
#    mxUpdatePanel(
#      panelId = "panelModal",
#      title = "Map creator",
#      subtitle= "Set layer, base map and settings for the new map",
#      background=F,
#      style="display:none",
#      html=list(
#        div(style="zoom:0.8",
#          selectInput("selectBaseMap","Select a base map",choices=mxConfig$tileProviders),
#          selectInput("selLayer","Select a vector tiles layer",choices="",selected=""),
#          selectInput("selColumn","Select a column",choices="",selected=""),
#          numericInput("sliderZoom","Set zoom",min=5,max=19,value=8,step=1),
#          #sliderInput("sliderZoom","Zoom",min=5,max=19,value=8,step=1),
#          numericInput("sliderOpacity","Opacity",min=0,max=1,value=0.2,step=0.2),
#          #sliderInput("sliderOpacity","Opacity",min=0,max=1,value=0.2,step=0.2),
#          uiOutput("outCoordinates")
#          )
#        ),
#      listActionButton=list( 
#        actionLink("importData_spatial","",icon=icon("plus-circle")),
#        actionLink("importData_table","",icon=icon("minus-circle"))
#        )
#
#
#      )
#


  



    #
    # MAIN MAP
    #
    output$mapxMap <- renderLeaflet({
      grp = "main"
      leaflet() %>%
      addTiles('http://localhost:3030/services/tiles/afg_base_layer/{z}/{x}/{y}.png',group=grp,options=list('zIndex'=10)) %>%
      addTiles('http://localhost:3030/services/tiles/afg_labels/{z}/{x}/{y}.png',group=grp,options=list('zIndex'=30))
    })

   observe({
     layId = "base"
     selBaseMap <- input$selectBaseMap 
     if(noDataCheck(selBaseMap)) return()
     if(selBaseMap=="NO_LAYER"){
       proxyMap <- leafletProxy("mapxMap")
       proxyMap %>%
       removeTiles(layId)
     }else{
       proxyMap <- leafletProxy("mapxMap")
       proxyMap %>%
       removeTiles(layId) %>%
       addProviderTiles(selBaseMap,layerId=layId,options=list('zIndex'=10))
     }
   })


    #
    # Get click feedback
    #
#    output$outCoordinates <- renderUI({
#      res <- input$mapxMap_click
#      isolate({
#        resOut <-dbGetValByCoord(dbInfo,table=input$selLayer,column=input$selColumn,lat=res$lat,lng=res$lng)
#      })
#      HTML(listToHtml(resOut,h=5))
#    })
#


    #
    # show debugger
    #
    observeEvent(input$btnDebug,{
      browser()
    })




    #
    # Data imporation manager
    #

    observeEvent(input$importData_spatial,{
      output$mxPanelModal <- renderUI({
        mxPanelModal(
          width=500,
          title="Data importation",
          subtitle="Import vector spatial dataset into map-x database.",
          html=tagList(
            uiOutput("importManager")
            ),
          defaultButtonText="cancel"
          )
      })
    })


    #
    # Data importation choose file
    #


    observe({
      dummy <- input$importData_spatial
      output$importManager <- renderUI({ tagList(
        tabsetPanel(type="pills",
          tabPanel(p("1"),tagList(
              fileInput("importData","Choose dataset",multiple=TRUE),
              p(lorem)
              )),
          tabPanel(p("2"),p("test")),
          tabPanel(p("3"),p("test"))
          )
        ) 
          })
    })


    #
    # Table importation
    #


    observeEvent(input$importData_table,{
      output$mxPanelModal <- renderUI({
        mxPanelModal(
          width=500,
          title="Table importation",
          subtitle="Import table dataset into map-x database.",
          html=tagList(
            p("test")
            ),
          listActionButton=list(
            actionButton("btnImportTest","submit test")
            ),
          background=FALSE
          )
      })
    })

    #
    # Populate and column selection
    #
    observe({
      mxCatch("Update input: pgrestapi layer list",{
        layers <- vtGetLayers(port=3030)
        if(!noDataCheck(layers)){
        updateSelectInput(session,"selLayer",choices=layers) 
        }
      })
    })

    #
    # Populate column selection
    # 

    observe({
      mxCatch("Update input: layer columns",{
        variables <- vtGetColumns(table=input$selLayer,port=3030,exclude=c("geom","gid"))$column_name
        if(!noDataCheck(variables)){
        updateSelectInput(session, "selColumn", choices=variables)
        }
      })
    })




    #
    # Add vector tiles
    #

    observe({ 
      lay <- input$selLayer
      grp <- "grp_001"
      zm  <- 8

      if(!noDataCheck(lay)){
        vars <- vtGetColumns(table=lay,port=3030)$column_name
        if(!noDataCheck(vars)){
          centro<-dbGetLayerCentroid(dbInfo=dbInfo,table=lay)
          if(noDataCheck(centro)){
            centro <- list(lng=0,lat=0)
            zm  = 1
          }
          proxyMap <- leafletProxy("mapxMap")
          proxyMap %>%
          clearGroup(grp) %>%
          addVectorTiles(
            url="localhost",
            port=3030,
            geomColumn="geom", # should be auto resolved by PGRestAPI
            idColumn="gid", # should be auto resolved by PGRrestAPI
            table=lay,
            dataColumn=vars,
            group = grp
            ) %>%
          setView(lng=centro$lng, centro$lat, zm)
          mxDebugMsg(" NEW LAYER ON MAP")
        }
      }
    })

    #
    # get selected variable summary
    #

    observe({
      lay = input$selLayer
      var = input$selColumn
      grp = "grp_001"

      isolate({

        if(!noDataCheck(lay) && !noDataCheck(var)){

          layerInfo <- dbGetColumnInfo(dbInfo,lay,var)


          if(noDataCheck(layerInfo)){
            return(NULL)
          }

          if(TRUE){
            mxDebugMsg(sprintf("Column info data retrieving for %s (%s) : %s",lay,var,layerInfo$timing['elapsed']))
          }

          if(noDataCheck(mxSession$layersInfo)){
            mxSession$layersInfo <- list()
          }

          type <- layerInfo$scaleType

          if(type == "continuous"){
             paletteChoice <- mxConfig$colorPalettes
          }else{
             paletteChoice<- "random"
          }

          if(noDataCheck(paletteChoice)) return()

            updateSelectInput(session,"selPalette",choices=paletteChoice)

          layerInfo$paletteChoice <-  paletteChoice

          mxSession$layersInfo[[grp]] <- layerInfo
          mxDebugMsg("Updated layer infos")

        }
      })
    })

    #
    #  Set layer colors
    #

    observe({
      grp <- "grp_001"
      layerInfo <-  mxSession$layersInfo[[grp]]
    
      selPalette <- input$selPalette
      selSize <- input$selSize
      selOpacity <- input$selOpacity

      paletteOk <- selPalette %in% layerInfo$paletteChoice
      
      
      isolate({

      if(!noDataCheck(layerInfo) && !noDataCheck(selPalette) && !noDataCheck(selSize) && !noDataCheck(selOpacity) && paletteOk){
       
       # mxCatch("Set layer palettes",{
     
          if(layerInfo$scaleType=="continuous") { 
            pal <- colorNumeric(
              palette <- selPalette,
              domain <- layerInfo$dValues
              )
          }else{
            pal <- colorFactor(
              hsv(runif(layerInfo$nDistinct),1,(runif(layerInfo$nDistinct)+1)/2,0.8),
              layerInfo$dValues
              )
          }
          
          layerStyle <-  list(
            col = pal(layerInfo$dValues),
            pal = pal,
            val = layerInfo$dValues,
            lay = layerInfo$table,
            var = layerInfo$column,
            opa = selOpacity,
            sze = selSize
            )

      #})

        if(noDataCheck(mxSession$layersStyle)){
          #mxSession$layersStyle <- list()
          mxSession$layersStyle <- list()
        }

      mxSession$layersStyle[[grp]] <- layerStyle

      }else{
        return()
      }
      })
    })


    

  

    # 
    # Update layer color and legend
    # 


    observe({
     

      grp = "grp_001"

      sty = mxSession$layersStyle[[grp]]

      vtStatus = input$leafletvtStatus

      isolate({
      if(!noDataCheck(sty) && !noDataCheck(vtStatus)){

      mxDebugMsg("Begin style")
      start = Sys.time()
      dCol <- sty$col
      dPal <- sty$pal
      dVal <- sty$val
      dVar <- sty$var
      dLay <- sty$lay
      dOpa <- sty$opa
      dSze <- sty$sze

      if(!noDataCheck(dCol) && !is.null(dPal) && !noDataCheck(dVal) && !noDataCheck(dVar)){
      proxyMap <- leafletProxy("mapxMap")


      proxyMap %>%
      addLegend(position="bottomright",pal=dPal,values=dVal,title=dLay,layerId = "legends")



      names(dCol) <- dVal
      jsColorsPalette <- sprintf("var colorsPalette=%s;",toJSON(dCol,collapse=""))
      jsDataCol <- sprintf("var dataColumn ='%s' ;",dVar)
      jsOpacity <- sprintf("var opacity =%s ;",dOpa)
      jsSize <- sprintf("var size =%s; ", dSze)
      jsUpdate <- sprintf("leafletvtGroup['%s'].setStyle(updateStyle,'%s');",grp,paste0(dLay,"_geom"))


      jsStyle = "updateStyle = function (feature) {
      var style = {};
      var selected = style.selected = {};
      var type = feature.type;
      var dataCol = hex2rgb(colorsPalette[feature.properties[dataColumn]],opacity);

      switch (type) {
        case 1: //'Point'
        style.color = dataCol;
        style.radius = size;
        selected.color = 'rgba(255,255,0,0.5)';
        selected.radius = 6;
        break;
        case 2: //'LineString'
        style.color = dataCol;
        style.size = size;
        selected.color = 'rgba(255,25,0,0.5)';
        selected.size = size;
        break;
        case 3: //'Polygon'
        style.color = dataCol;
        style.outline = {
          color: dataCol,
          size: size
        };
        selected.color = 'rgba(255,0,0,0.3)';
        selected.outline = {
          color: 'rgba(255,0,0,1)',
          size: size
        };
        break;
      };
      return style;

      };
      "
      jsTime = "var d= new Date(); console.log(d + d.getMilliseconds())"

      jsCode = paste(
        jsColorsPalette,
        jsDataCol,
        jsOpacity,
        jsSize,
        jsStyle,
        jsUpdate
        )

      cat("\n")
    #  cat(jsCode)
      cat("\n")
  session$sendCustomMessage(type="jsCode",list(code=jsTime))
  session$sendCustomMessage(type="jsCode",list(code=jsCode))

          setLayerZIndex(zIndex=15)
      }
    
      stop <- Sys.time() - start
      mxDebugMsg(paste("End style. Timing=",stop))
      
      }
    })
    })

   
    #
    # Populate column selection
    # 

#    observe({
#      mxCatch("Update input: layer columns",{
#       # updateSelectInput(session, "selColumn",choices=mxSession$columnsInfo$column_name)
#        cols = vtGetColumns(table=input$selLayer,port=3030,exclude=c("geom","gid"))
#      })
#    })


    #
    # populate column info reactive values, take reactivity on layer selection
    #
#
#    observe({
#      mxCatch("Update mxSession: get layer columns",{
#        mxSession$columnsInfo <- vtGetColumns(table=input$selLayer,port=3030,exclude=c("geom","gid"))
#      })
#    })
#
#
#
#    observe({
#    print(input$leafletvtClickCoord)
#    print(input$leafletvtClickProp)
#    })





    #
    # update legends and colors
    #

#    observe({
#  
#
#      if(FALSE){
#
#      # addProviderTiles(baseLayer,group=grp)%>%
#      dCol <- mxSession$col
#      dPal <- mxSession$pal
#      dVal <- mxSession$val 
#
#      vCol <- as.list(dCol)
#      names(vCol) <- dVal
#
#      baseLayer <- input$selectBaseMap
#
#      grp = "grp_001"
#
#      if(!noDataCheck(dCol) && !noDataCheck(dVal) && !noDataCheck(baseLayer)){
#        mxCatch("Add vector tiles and zoom",{
#          proxyMap <- leafletProxy("mapxMap")
#          #ext<-dbGetLayerExtent(dbInfo=dbInfo,table=input$selLayer)  
#          centro<-dbGetLayerCentroid(dbInfo=dbInfo,table=input$selLayer)  
#          if(noDataCheck(centro))return()
#          proxyMap %>%
#          clearGroup(grp) %>%
#          addTiles('http://localhost:3030/services/tiles/afg_labels/{z}/{x}/{y}.png')%>%
#          addVectorTiles(
#            url="localhost",
#            port=3030,
#            table=input$selLayer,
#            dataColumn=input$selColumn,
#            group = grp
#            )%>%
#          addLegend(position="bottomright",pal=dPal,values=dVal,title=input$selLayer,layerId = "legends")%>%
#          setView(lng=centro$lng, centro$lat, isolate(input$sliderZoom))
#      })
#      }
#      }
#
# 
#    })
#

    # set opacity
#    observe({
#      opacity=input$selOpacity
#      if(!noDataCheck(opacity)){ 
#        setLayerOpacity(opacity=opacity)
#      }
#    })
#
#    observe({
#      mapZoom <- input$mapxMap_zoom
#      if(!noDataCheck(mapZoom))
#        updateSliderInput(session=session,"sliderZoom",value=mapZoom) 
#        return(NULL)
#    })
#
#    observe({
#      sliderZoom <- input$sliderZoom
#      if(!noDataCheck(sliderZoom)){
#          proxyMap <- leafletProxy("mapxMap")
#          proxyMap %>%
#          setZoom(sliderZoom)
#      }
#    })
#
    observe({
    mxDebugMsg(input$mapxMap_bounds)
    })


    #
    # SHOW INDEX
    #



    observe({

      mxCatch("Plot WDI data",{
        idx = input$selectIndicator
        cnt = mxSession$selectCountry

        if(!noDataCheck(idx) && !noDataCheck(cnt)){
          dat <- WDI(
            indicator = idx, 
            country = countrycode(cnt,'iso3c','iso2c'), 
            start = 1980, 
            end = 2015
            )

          dat = na.omit(dat)
          if(exists('dat') && nrow(dat)>0){
            dat$year <- as.Date(paste0(dat$year,'-12-31'))
            datSeries <- xts(dat[,idx],order.by=dat$year)
            idxName = names(mxConfig$wdiIndicators[idx])
            graphIndicator = dygraph(
              data=datSeries,
              main=idxName,
              ylab=idxName) %>% 
            dyRangeSelector()
            output$dyGraphWdi <- renderDygraph({
              graphIndicator
            })
          }
        }
      })
    })




  }

  shinyApp(ui, server)



  # test
  #if(FALSE){
  #  spatialObj<-dbGetSp(dbInfo=d,"SELECT * FROM wdpa_afg_polygons_webmercator")
  #  test<-dbGetGeoJSON(dbInfo=d,"SELECT * FROM wdpa_afg_polygons_webmercator")
  #  drv <- dbDriver("PostgreSQL")
  #  dbCon<- dbConnect(drv,host="129.194.205.12",dbname="mapx",user="mapxowner",password="opengeox",port=5432)
  #  dbCon<- dbConnect(drv,host="129.194.205.12",dbname="mapx",user="postgres",password="opengeox",port=5432)
  #  tableList<-dbListTables(dbCon)
  #  for(i in tableList){
  #    a=dbGetQuery(dbCon,sprintf("SELECT UpdateGeometrySRID("public", "%s", "geom", 4326) ;",i))
  #  }
  #  test<-dbGetQuery(dbCon,"SELECT * FROM afg__displaced_from__2013__a")
  #}
#
#uiIntro_orig <- tagList(
#  #
#  # HEADER
#  #
#  tags$header(class="intro",
#    div(class="intro-body",
#      div(class="container",
#        div(class="row",
#          div(class="col-md-8 col-md-offset-2",
#            h1(class='brand-heading',"MAP-X"),
#            hr(),
#            tags$p(class="intro-text",
#              "Mapping and Assessing the Performance of Extractive Industries in Emerging Economies and Fragile States."
#              ),
#            hr(),
#            tags$p(tags$img(src="img/logo_grid_white_en.svg",style="height:100px;")),
#            hr()
#            )
#          )
#        )  
#      )
#    )
#  )


#
#
#
#  ui_orig <- tagList(
#    tags$head(
#      tags$link(href="font-awesome-4.4.0/css/font-awesome.min.css",rel="stylesheet",type="text/css"),
#      tags$link(href="theme/greyscale/grayscale.css"),
#      tags$link(href="theme/greyscale/bootstrap.min.css"),
#      tags$link(href="mapx/mapx.css",rel="stylesheet",type="text/css")
#      ),
#    #
#    # NAVIGATION
#    #
#    #
#    #  tags$div(class="top_country_select",
#    #    ),
#
#
#    #  selectInput("selectCountry","Select an EITI country",choices=mxConfig$countryListChoices),
#
#    tags$a(id="menu-toggle",href="#",class="btn btn-dark btn-lg toggle",icon("bars")),
#    tags$nav(id="sidebar-wrapper",
#      tags$ul(class="sidebar-nav",
#        tags$a(id="menu-close",href="#", class="btn btn-light btn-lg pull-right toggle",icon("times")),
#        tags$li("Navigation",
#          tags$ul(class="sidebar-sublist",
#            tags$li(class="sidebar-brand",tags$a(href="#top", "Map-x")),
#            tags$li(tags$a(href="#about","About")),
#            tags$li(tags$a(href="#country","Country data")),
#            tags$li(tags$a(href="#map","Map")),
#            tags$li(tags$a(href="#contact","Contact")),
#            )
#          ),
#        tags$li('Country selection',
#          selectInput("selectCountry","Select an EITI country",choices=mxConfig$countryListChoices)
#          # mxConfig$countryListHtml
#          )
#        )
#      ),
#
#    #
#    # ALERTS 
#    #
#    uiOutput("panelAlert"),
#    #
#    # HEADER
#    #
#    tags$header(id="top",class="header",
#      div(class="text-vertical-center big-title-container",
#        div(class="row",
#          div(class="col-md-8 col-md-offset-2",
#            h1(class='brand-heading',"MAP-X"),
#            hr(),
#            tags$p(class="intro-text",
#              "Mapping and Assessing the Performance of Extractive Industries in Emerging Economies and Fragile States."
#              ),
#            hr(),
#            tags$p(tags$img(src="img/logo_grid_white_en.svg",style="height:100px;")),
#
#            hr(),
#            tags$a(href="#map",class="btn btn-circle page-scroll",
#              tags$i(class="fa fa-globe animated")
#              ),
#            tags$a(href="#charts",class="btn btn-circle page-scroll",
#              tags$i(class="fa fa-bar-chart animated")
#              ),
#            tags$a(href="#map",class="btn btn-circle page-scroll",
#              tags$i(class="fa fa-map-o animated")
#              ),
#            tags$a(href="#map",class="btn btn-circle page-scroll",
#              tags$i(class="fa fa-plus animated")
#              ),
#            tags$a(href="#about",class="btn btn-circle page-scroll",
#              tags$i(class="fa fa-info animated")
#              )
#            )
#          )
#        )
#      ),
#
#    #
#    # COUNTRY INFO
#    #
#    tags$section(id="charts",class="about",
#      div(class="container"),
#      div(class="row",
#        div(class="col-lg-12 text-center",
#          div(class="col-lg-10 col-lg-offset-1",
#            h2("Country indicators"),
#            hr(class="small"),
#            fluidRow(
#              column(width=6,
#                p("")
#                #selectInput("selectCountry","Select an EITI country",choices=mxConfig$countryListChoices)
#                ),
#              column(width=6,
#                tabsetPanel(type="pills",
#                  tabPanel('Ressource gouvernance index',
#                    tags$canvas(id="testChart",width="500px",height="300px")
#                    ),
#                  tabPanel("World bank indicators", 
#                    tags$canvas(id="testChart2",width="500px",height="300px")
#                    )
#                  )
#                )
#              )
#            )
#          )
#        )
#      ),
#    #
#    # MAP
#    #
#    tags$section(id="map",class="about",
#      div(class="container"),
#      div(class="row",
#        div(class="col-lg-12 text-center",    
#          leafletOutput("mapxMap",height="400px")
#          )
#        )
#      ),
#    #
#    # MAP CREATOR
#    #
#    tags$section(id="map",class="about",
#      div(class="container"),
#      div(class="row",
#        div(class="col-lg-12 text-center",
#          h2("Map Creator"),
#          div(style="zoom:0.8",
#            selectInput("selectBaseMap","Select a base map",choices=mxConfig$tileProviders),
#            selectInput("selLayer","Select a vector tiles layer",choices="",selected=""),
#            selectInput("selColumn","Select a column",choices="",selected=""),
#            numericInput("sliderZoom","Set zoom",min=5,max=19,value=8,step=1),
#            #sliderInput("sliderZoom","Zoom",min=5,max=19,value=8,step=1),
#            numericInput("sliderOpacity","Opacity",min=0,max=1,value=0.2,step=0.2),
#            #sliderInput("sliderOpacity","Opacity",min=0,max=1,value=0.2,step=0.2),
#            uiOutput("outCoordinates")
#            )
#          )
#        )
#      ),
#    #
#    # ABOUT
#    #
#    tags$section(id="about",class="about",
#      div(class="container"),
#      div(class="row",
#        div(class="col-lg-12 text-center",
#          p("")
#          )
#        )
#      ),
#
#    #
#    #
#    #
#
#    #
#    # Scripts
#    #
#
#    # custom mapx script
#    includeScript("www/mapx/mapx.js"),
#
#    # chart js 
#    includeScript("www/chartjs/Chart.min.js"),
#
#    # grayscale theme
#    includeScript("www/theme/grayscale/grayscale.js"),
#    includeScript("www/theme/grayscale/jquery.easing.min.js")
#
#
# 
#
#    )

#
# hr(),
#          radioButtons('radioBtnYearSpanType',
#            inline=TRUE,
#            label="Choose year span method",
#            choices=c("Use slider"="yearSlider","Use layer column"="yearColumn")
#            ),
#          conditionalPanel(condition="input.radioBtnYearSpanType == 'yearSlider'",  
#          sliderInput("sliderYearSpan","Set year span",min=1950,max=2015,round=TRUE,sep="",value=c(1980L,2010L),ticks=1)
#            ),
#          conditionalPanel(condition="input.radioBtnYearSpanType == 'yearColumn'",
#           selectInput("columnYearSpan","Select a column containing the years", choices="")
#            ),
#          uiOutput("outCoordinates")
#
