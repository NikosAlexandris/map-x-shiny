
#source("fun.R")
source("loadlib.R")
source("fun/helperUi.R")
source("settings/settings.R")
source("config.R")

# NOTE : mvt exemple in Documents/unep_grid/map-x/test/Leaflet.MapboxVectorTile-master/examples/

#
# UI
#

ui <- fluidPage(class="fullPage",
  tags$head(
    tags$link(rel="stylesheet",type="text/css",href="mapx.css"),
    tags$script(src="mapx.js"),
    tags$script(src="chartjs/Chart.min.js")
    ), 
  # register panels :
  uiOutput("panelAlert"),
  uiOutput("panelModal"),
  uiOutput("panelMain"),
  div(class="outer",
    leafletOutput("mapxMap")
    )
  )




mxUpdateChartRadar <- function(session=shiny::getDefaultReactiveDomain(),main,id,labels,values){

  stopifnot(is.vector(values) || is.vector(label))

  ctx = sprintf("var ctx = document.getElementById('%s').getContext('2d');",id)
 
  createGraph = "var myRadarChart = new Chart(ctx).Radar(data);"

  data = toJSON(values)
  
  labels = toJSON(labels)

  js = sprintf("
  /* create chart.js object*/
  var data = {
  labels: %s,
  datasets: [
  {
    label: '%s',
    fillColor: 'rgba(220,220,220,0.2)',
    strokeColor: 'rgba(220,220,220,1)',
    pointColor: 'rgba(220,220,220,1)',
    pointStrokeColor: '#fff',
    pointHighlightFill: '#fff',
    pointHighlightStroke: 'rgba(220,220,220,1)',
    data: %s
  }
  ]
};
/* get context  */
%s
%s
",labels,main,data,ctx,createGraph)

session$sendCustomMessage(
    type="jsCode",
    list(code=js)
    )

}


#
# Server
#
server <- function(input, output, session) {

 #  session$onFlushed(toggleClass(class=".test"),once=TRUE)
 
 


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
          choices=config$countryList),
        tabsetPanel(type="pills",
          tabPanel(p('Narratives'),
            h4('Ressource gouvernance index'),
        tags$canvas(id="testChart",width="500px",height="300px")
            ),
        tabPanel(p("World bank indicators"),tagList(
        selectizeInput(
          inputId="selectIndicator",
          label="Select an indicator",
          choices=config$wdiIndicators,
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


  mxUpdatePanel(
    panelId = "panelModal",
    title = "Map creator",
    subtitle= "Set layer, base map and settings for the new map",
    background=F,
    style="display:none",
    html=list(
      div(style="zoom:0.8",
        selectInput("selectBaseMap","Select a base map",choices=config$tileProviders),
        selectInput("selLayer","Select a vector tiles layer",choices="",selected=""),
        selectInput("selColumn","Select a column",choices="",selected=""),
        numericInput("sliderZoom","Set zoom",min=5,max=19,value=8,step=1),
        #sliderInput("sliderZoom","Zoom",min=5,max=19,value=8,step=1),
        numericInput("sliderOpacity","Opacity",min=0,max=1,value=0.2,step=0.2),
        #sliderInput("sliderOpacity","Opacity",min=0,max=1,value=0.2,step=0.2),
        uiOutput("outCoordinates")
        )
      ),
    listActionButton=list( 
      actionLink("importData_spatial","",icon=icon("plus-circle")),
      actionLink("importData_table","",icon=icon("minus-circle"))
      )


    )



  # set reactive values
  mxSession <- reactiveValues()


  observe({
    cntry = input$selectCountry
    if(! noDataCheck(cntry)){

      dat = mxData$rgi_score_2013
      dat = dat[dat$iso3 == cntry,]
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

  })



  #
  # MAIN MAP
  #
  output$mapxMap <- renderLeaflet({
    grp = "group_main"
      leaflet() %>%
      addProviderTiles(config$tileProviders[[1]],group=grp,
        options = providerTileOptions(noWrap = TRUE)
        ) %>% addProviderTiles("Stamen.TonerHybrid",group=grp,
        options = providerTileOptions(opacity = 0.60,zIndex=10)
        ) 
  })


  #
  # Get click feedback
  #
  output$outCoordinates <- renderUI({
    res <- input$mapxMap_click
    isolate({
      resOut <-dbGetValByCoord(dbInfo,table=input$selLayer,column=input$selColumn,lat=res$lat,lng=res$lng)
    })
    HTML(listToHtml(resOut))
  })



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
 # Populate layer selection
 #
  observe({
    mxCatch("Update input: pgrestapi layer list",{
      updateSelectInput(session,"selLayer",choices=vtGetLayers(port=3030)) 
    })
  })


 #
 # populate column info reactive values, take reactivity on layer selection
 #

  observe({
    mxCatch("Update mxSession: get layer columns",{
      mxSession$columnsInfo <- vtGetColumns(table=input$selLayer,port=3030,exclude=c("geom","gid"))
    })
  })



  #
  # Populate column selection
  # 

  observe({
    mxCatch("Update input: layer columns",{
      updateSelectInput(session, "selColumn",choices=mxSession$columnsInfo$column_name)
    })
  })

  #
  # get selected column summary
  #
  observeEvent(input$selColumn,{
    mxCatch(paste("Get column info for",input$selLayer,":",input$selColumn),{
      cSummary<-dbGetColumnInfo(dbInfo,input$selLayer,input$selColumn)
      if(!noDataCheck(cSummary)){  
        if(cSummary$scaleType=="continuous") { 
          pal <- colorNumeric(
            palette="Blues",
            domain=cSummary$dValues
            )
        }else{
          pal <- colorFactor(
            hsv(runif(cSummary$nDistinct),1,(runif(cSummary$nDistinct)+1)/2,0.8),
            #topo.colors(cSummary$nDistinct),
            cSummary$dValues
            )
        }

        mxSession$col <- pal(cSummary$dValues)
        mxSession$pal <- pal
        mxSession$val <- cSummary$dValues

      }else{
        return()
      }

    })

  })


  #
  # update map with new layer 
  #
  observe({
    dCol <- mxSession$col
    dPal <- mxSession$pal
    dVal <- mxSession$val 

    vCol <- as.list(dCol)
    names(vCol) <- dVal

    baseLayer <- input$selectBaseMap

    grp = "grp_001"
    
    if(!noDataCheck(dCol) && !noDataCheck(dVal) && !noDataCheck(baseLayer)){
      mxCatch("Add vector tiles and zoom",{
        proxyMap <- leafletProxy("mapxMap")
        #ext<-dbGetLayerExtent(dbInfo=dbInfo,table=input$selLayer)  
        centro<-dbGetLayerCentroid(dbInfo=dbInfo,table=input$selLayer)  
        if(noDataCheck(centro))return()
        proxyMap %>%
        clearGroup(grp) %>%
        addVectorTiles(
          table=input$selLayer,
          dataColumn=input$selColumn,
          opacity=isolate(input$sliderOpacity),
          size=5,
          valueColor=vCol,
          group = grp
          )%>%
       addProviderTiles(baseLayer,group=grp)%>%
        addLegend(position="bottomright",pal=dPal,values=dVal,title=input$selLayer,layerId = "legends")%>%
        setView(lng=centro$lng, centro$lat, isolate(input$sliderZoom))
    })
    }

  })


  # set opacity
  observe({
    opacity=input$sliderOpacity
   if(!noDataCheck(opacity)){ 
    setLayerOpacity(opacity=opacity)
   }
  })

 observe({
   mapZoom <- input$mapxMap_zoom
   if(!noDataCheck(mapZoom))
   updateSliderInput(session=session,"sliderZoom",value=mapZoom) 
 })

 observe({
    dCol <- mxSession$col
    dPal <- mxSession$pal
    dVal <- mxSession$val 

    vCol <- as.list(dCol)
    names(vCol) <- dVal

    if(!noDataCheck(dCol) && !noDataCheck(dVal)){
      mxCatch("Set zoom",{
        proxyMap <- leafletProxy("mapxMap")

        proxyMap %>%
        setZoom(input$sliderZoom)

    })
    }

  })


 #
 # SHOW INDEX
 #



 observe({

   mxCatch("Plot WDI data",{
     idx = input$selectIndicator
     cnt = input$selectCountry

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
         idxName = names(config$wdiIndicators[idx])
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
