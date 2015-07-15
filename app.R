
#source('fun.R')
source('loadlib.R')
source('settings/settings.R')

# NOTE : mvt exemple in Documents/unep_grid/map-x/test/Leaflet.MapboxVectorTile-master/examples/







#
# UI
#
ui <- fluidPage(
  tags$head(
    tags$link(rel="stylesheet",type="text/css",href='mapx.css')
    ),
  leafletOutput("mapxMap",width="100%", height="100%"),
  fluidRow(
    column(width=3,
      h4('Map-x'),
      p('This is the technical proof of concept version of map-x.'),
      selectInput('selLayer','Select a vector tiles layer',choices="",selected=""),
      selectInput('selColumn',"Select a column",choices='',selected="")
      )
    )
  )



ui <- tagList(
  tags$head(
    tags$link(rel="stylesheet",type="text/css",href='mapx.css')
    ), 
  div(class="outer",
    leafletOutput("mapxMap"),
    # Shiny versions prior to 0.11 should use class="modal" instead.
    absolutePanel(id = "controls", class = "panel panel-default", fixed = TRUE,
      draggable = TRUE, top = 60, left = 20, right = "auto", bottom = "auto",
      width = 330, height = "auto",
      h4('Map-x'),
      p('This is the technical proof of concept version of map-x.'),
      selectInput('selLayer','Select a vector tiles layer',choices="",selected=""),
      selectInput('selColumn',"Select a column",choices='',selected="")
      )
    )
  )

#
# Server
#
server <- function(input, output, session) {

  # set reactive values
  mxSession <- reactiveValues()



  output$mapxMap <- renderLeaflet({
    leaflet() %>%
    addProviderTiles("Acetate.terrain",
      options = providerTileOptions(noWrap = TRUE)
      ) %>% addProviderTiles("MapBox.helsinki.afghanistan_labels",
      options = providerTileOptions(opacity = 0.60)
      )  
  })
  observeEvent(input$btnDebug,{
    browser()
  })
  #populate select layer list
  observe({
    updateSelectInput(session,"selLayer",choices=vtGetLayers()) 
  })


  observe({
    #mxSession$columnsInfo <- vtGetColumns(table=input$selLayer,exclude=c('geom','gid','province'))
    mxSession$columnsInfo <- vtGetColumns(table=input$selLayer,exclude=c('geom','gid'))
  })
  #populate select column list
  observe({
   updateSelectInput(session, "selColumn",choices=mxSession$columnsInfo$column_name)
  })

  # get column values
 
  noDataCheck<-function(val){
    if(!is.vector(val)) return(TRUE)
  any(c(isTRUE(is.null(val)),isTRUE(is.na(val)),isTRUE(nchar(val)==0)))
  }

  dbGetColumnInfo<-function(dbInfo,table,column){
    if(noDataCheck(dbInfo) || noDataCheck(table) || noDataCheck(column) || isTRUE(column=='gid'))return() 
    d=dbInfo
    tryCatch({
      timing<-system.time({
      drv <- dbDriver("PostgreSQL")
      con <- dbConnect(drv, dbname=d$dbname, host=d$host, port=d$port,user=d$user, password=d$password)
      nR <- dbGetQuery(con,sprintf("SELECT count(*) FROM %s WHERE %s IS NOT NULL",table,column))[[1]]   
      nN <- dbGetQuery(con,sprintf("SELECT count(*) FROM %s WHERE %s IS NULL",table,column))[[1]]
      nD <- dbGetQuery(con,sprintf("SELECT COUNT(DISTINCT(%s)) FROM %s WHERE %s IS NOT NULL",column,table,column))[[1]]
      #tC <- dbGetQuery(con,sprintf("SELECT pg_typeof(%s) FROM %s LIMIT 1",column,table)) 
      val <- dbGetQuery(con,sprintf("SELECT DISTINCT(%s) FROM %s WHERE %s IS NOT NULL",column,table,column),stringAsFactors=T)[[1]]
      })


      #scaleType <- ifelse(is.factor(val) || is.character(val) || (isTRUE(nD/nR<0.05 && is.numeric(val[[1]][1]))),'discrete','continuous')
      scaleType <- ifelse(is.factor(val) || is.character(val),'discrete','continuous')
     
      return(list(
          'nDistinct'=nD,
          'nRow'=nR,
          'nNa'=nN,
          'scaleType'=scaleType,
          'dValues'=val,
          'timing'=timing
          )) 
    },finally={
      dbDisconnect(con)
    })
  }


  observe({
    selCol <- input$selColumn
    #selColFun <- input$selColFun

    isolate({
    cSummary<-dbGetColumnInfo(dbInfo,input$selLayer,selCol)
    if(!noDataCheck(cSummary)){  
      if(cSummary$scaleType=='continuous') { 
        pal <- colorNumeric(
          palette='Blues',
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




  #  points <- eventReactive(input$recalc, {
  #    cbind(rnorm(40) * 2 + 69, rnorm(40) + 34)
  #  }, ignoreNULL = FALSE)

  observe({
    dCol <- mxSession$col
    dPal <- mxSession$pal
    dVal <- mxSession$val 

    vCol <- as.list(dCol)
    names(vCol) <- dVal

    if(!noDataCheck(dCol) && !noDataCheck(dVal)){
        proxyMap <- leafletProxy('mapxMap')
        ext<-dbGetLayerExtent(dbInfo=dbInfo,table=input$selLayer)  
        if(noDataCheck(ext))return()
        proxyMap %>% 
        addVectorTiles(table=input$selLayer,dataColumn=input$selColumn,opacity=0.2,valueColor=vCol)%>%
        addLegend(position="bottomright",pal=dPal,values=dVal,title=input$selLayer,layerId = 'legends')%>%
        fitBounds(
          lng1=ext$lng1,
          lat1=ext$lat1,
          lng2=ext$lng2,
          lat2=ext$lat2)
    }
  })

}

shinyApp(ui, server)



# test
#if(FALSE){
#  spatialObj<-dbGetSp(dbInfo=d,"SELECT * FROM wdpa_afg_polygons_webmercator")
#  test<-dbGetGeoJSON(dbInfo=d,"SELECT * FROM wdpa_afg_polygons_webmercator")
#  drv <- dbDriver('PostgreSQL')
#  dbCon<- dbConnect(drv,host="129.194.205.12",dbname="mapx",user="mapxowner",password="opengeox",port=5432)
#  dbCon<- dbConnect(drv,host="129.194.205.12",dbname="mapx",user="postgres",password="opengeox",port=5432)
#  tableList<-dbListTables(dbCon)
#  for(i in tableList){
#    a=dbGetQuery(dbCon,sprintf("SELECT UpdateGeometrySRID('public', '%s', 'geom', 4326) ;",i))
#  }
#  test<-dbGetQuery(dbCon,"SELECT * FROM afg__displaced_from__2013__a")
#}
