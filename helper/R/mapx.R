#' Map-x helper functions
#'
#' Map-x core functions
#'
#'
#' @docType package
#' @name mapxhelper 
NULL

#' Check for no null, NA's, nchar of 0, lenght of 0  or "[NO DATA]" string in a vector.
#' @param val  Vector to test for no data.
#' @return TRUE if no data (nchar == 0 OR is.na OR is.null) found or if input is not a vector
#' @export
noDataCheck<-function(val,useNoData=TRUE,noDataVal="[ NO DATA ]"){
  #if(!is.vector(val)) stop(paste("val should be a vector. Provided value=",typeof(val)))
  if(!is.vector(val)){
    return(TRUE)
  }
  if(useNoData){
  noData <- all(noDataVal %in% val)
  }else{
  noData <- FALSE
  }
  any(c(isTRUE(is.null(val)),isTRUE(is.na(val)),isTRUE(nchar(val)==0),isTRUE(length(val)==0),noData))
}



#' Test for internet connection. 
#' The idea is to reach google with a ping and determine if there is a full packet response without loss
#' 
#' @param host String. Host name to ping
#' @export
mxCanReach<- function(server="google.com",port=80){

  req <- sprintf(
      "if nc -z %1$s %2$s; then echo '1'; else echo '0';fi;",
      server,
      port
      )

  any( system(req,intern=T) == "1")

}






#' Create a chartRadar in a canvas element.
#'
#' Search the dom for an id a get drawing context, create a new chart object and config it with data.
#'
#' @param session Shiny reactive session
#' @param main Main label
#' @param compMain Comparative value label
#' @param id Id of the canvas
#' @param idLegend Id of the legend
#' @param labels Labels for value and comparative values
#' @param value Values
#' @param compValues Comparative values
#' @export
mxUpdateChartRadar <- function(session=shiny::getDefaultReactiveDomain(),main,compMain,id,idLegend,labels,values,compValues){
  stopifnot(is.vector(values) || is.vector(label))
  ctx = sprintf("var ctx = document.getElementById('%s').getContext('2d');",id)
  createGraph = "var mxChart = new Chart(ctx).Radar(data)"
  labels = jsonlite::toJSON(labels)
  datasetMain = jsonlite::toJSON(auto_unbox=T,
    list(
      label = main,
      fillColor = 'rgba(119,119, 119, 0.6)',
      strokeColor = 'rgba(119,119, 119, 0.6)',
      highlightFill = 'rgba(119,119, 119, 0.6)',
      highlightStroke = 'rgba(119,119, 119, 0.6)',
      data = values
      )
    )
  datasetComp = jsonlite::toJSON(auto_unbox=T,
    list(
      label = compMain,
      fillColor = 'rgba(255, 164, 0, 0.8)',
      strokeColor = 'rgba(255, 164, 0, 0.9)',
      highlightFill = 'rgba(255, 164, 0, 0.8)',
      highlightStroke = 'rgba(255, 164, 0, 1)',
      data = compValues
      )
    )
  js = sprintf("
    /* create chart.js object*/
    var data = {
      labels: %s,
      datasets: [ %s , %s ]
    };
    /* context */
    %s
    /*create graph */
    %s
    /* Generate legend */
    var chartLegend = mxChart.generateLegend();
    $('#'+'%s').html(function(){return chartLegend;});",
    labels,datasetComp,datasetMain,ctx,createGraph,idLegend)
    session$sendCustomMessage(
      type="jsCode",
      list(code=js)
      )
}

#
##' Hide element by id with animation
##' @param session Shiny session
##' @param id Html id
##' @param duration Duraiton in milisecond
##' @export
#mxJsHide <- function(session=getDefaultReactiveDomain(),id="loading-content",duration=2000){ 
#  function(){
#  js=sprintf("var el = document.getElementById('%1$s'); el.style.opacity=0;",id)
#  session$sendCustomMessage(
#    type="jsCode",
#    list(code=js)
#    )
#  }
#}






#' Print debug message
#'
#' Print a defaut debug message with date as prefix. NOTE: this function should take a global parameter "debug" and a log file.
#'
#' @param m Message to be printed
#' @return NULL
#' @export
mxDebugMsg <- function(text=""){ 
  m <- text
  options(digits.secs=6)
  cat(paste0("[",Sys.time(),"] ",m,'\n'))
}

mxConsoleText <- function(text=""){
 nc <- nchar(text)
 lc <- 79-nc
 mc <- lc %/% 2
 bar <- paste(rep("-",mc),collapse="")
 out <- paste0(bar,text,bar,"\n",sep="")
cat(out)
}

mxDebugToJs<-function(text,session=getDefaultReactiveDomain()){
  js <- jsonlite::toJSON(text)
  res <- list(
    msg=text
    )
  session$sendCustomMessage(
    type="jsDebugMsg",
    res
    )
}


#' Create a modal panel
#'
#' Create a modal panel with some options as custom button, close button, html content. 
#'
#' @param id Panel id
#' @param title Panel title
#' @param subtitle Panel subtitle
#' @param html HTML content of the panel, main text
#' @param listActionButton If FALSE, hide buttons. If NULL, display default close panel button, with text given in defaultButtonText. If list of buttons, list of button.
#' @param defaultButtonText Text of the default button if listActionButton is NULL and not FALSE
#' @param style Additional CSS style for the panel 
#' @param class Additional class for the panel
#' @param hideCloseButton Boolean. Hide the close panel button
#' @param draggable Boolean. Set the panel as draggable
#' @export
mxPanel<- function(id="default",title=NULL,subtitle=NULL,html=NULL,listActionButton=NULL,background=TRUE,addCancelButton=FALSE,addOnClickClose=TRUE,defaultButtonText="OK",style=NULL,class=NULL,hideCloseButton=FALSE,draggable=TRUE,fixed=TRUE){ 

  classModal <- "panel-modal"
  rand <- randomName()

  idBack <- paste(id,rand,"background",sep="_")
  idContent <- paste(id,rand,"content",sep="_")
  jsHide <- paste0("$('#",idContent,"').toggle();$('#",idBack,"').toggle()")
  

  if(!is.null(listActionButton) && isTRUE(addOnClickClose)){
    listActionButton <- lapply(
      listActionButton,
      function(x){
        x$attribs$onclick<-jsHide
        return(x)
      }
      )
  }  
  
  # If NULL Set default button action to "close" panel, with custom text

  if(is.null(listActionButton)){
    listActionButton=list(
    tags$button(onclick=jsHide,defaultButtonText,class="btn btn-modal")
    )
  }

  if(addCancelButton){
  listActionButton <- tagList(
    listActionButton, 
    tags$button(onclick=jsHide,"Cancel",class="btn btn-modal")
    )
  }

  # if explicit FALSE is given, remove modal button. 
  if(isTRUE(is.logical(listActionButton) && !isTRUE(listActionButton)))listActionButton=NULL
# close button handling
  if(hideCloseButton){
    closeButton=NULL
  }else{
    closeButton=a(href="#", onclick=jsHide,style="float:right;color:black",icon('times'))
  }

  if(background){
    backg <- div(id=idBack,class=paste("panel-modal-background"))
  }else{
    backg <- character(0)
  }



  if(draggable){
  scr <- tags$script(sprintf("
    $('#%1$s').draggable({ 
      cancel: '.panel-modal-text'
    });
    ",idContent))
  }else{
  scr = ""
  }

  if(fixed){
  style = paste("position:fixed",style)
  }else{
  style = paste("position:absolute",style)
  }

  tagList( 
    backg,
    div( 
      id=idContent,
      class=paste(class,classModal,"panel-modal-content"),
      style=style,
      closeButton,
      div(class=paste('panel-modal-head'),  
        div(class=paste('panel-modal-title'),title)
        ),
      div(class=paste('panel-modal-subtitle'),subtitle),
      hr(),
      div(class=paste('panel-modal-text'),html),
      hr(),
      div(class=paste('panel-modal-buttons'),
        listActionButton
        )
      ),
    scr
    )

  
}


#  tagList( 
#    backg,
#    absolutePanel(draggable=draggable,
#      id=idContent,
#      class=paste(class,classModal,"panel-modal-content"),
#      style=style,
#      closeButton,
#      div(class=paste(classModal,'panel-modal-head'),  
#        div(class=paste(classModal,'panel-modal-title'),title)
#        ),
#      div(class=paste(classModal,'panel-modal-subtitle'),subtitle),
#      hr(),
#      div(class=paste(classModal,'panel-modal-text'),html),
#      hr(),
#      div(class=paste(classModal,'panel-modal-buttons'),
#        listActionButton
#        )
#      )
#    )
#
#' Update existing panel
#'
#' Use output object to update the panel with a known id. E.g. for updating uiOutput("panelTest"), use mxUpdatePanel with panelId "panelTest"
#'
#' @param panelId Id of the existing panel
#' @param session Shiny reactive object of the session
#' @param ... Other mxPanel options
#' @export
mxUpdatePanel <- function(panelId=NULL,session=shiny:::getDefaultReactiveDomain(),...){
  session$output[[panelId]] <- renderUI(mxPanel(id=panelId,...))
}

#' Alert panel
#'
#' Create an alert panel. This panel could be send to an output object from a reactive context. 
#'
#' @param title Title of the alert. Should be "error", "warning" or "message"
#' @param subtitle Subtitle of the alert
#' @param message html or text message for the alert
#' @param listActionButtons List of action button for the panel
#' @export
mxPanelAlert <- function(title=c("error","warning","message"),subtitle=NULL,message=NULL,listActionButton=NULL,...){ 
  title = match.arg(title)
  switch(title,
    'error'={title=h2(icon("exclamation-circle"),toupper(title))},
    'warning'={title=h2(icon("exclamation-triangle"),toupper(title))},
    'message'={title=h2(icon("info-circle"),toupper(title))} 
    )
  mxPanel(class="panel-overall panel-fixed",title=title,subtitle=subtitle,html=message,listActionButton=listActionButton,style="position:fixed;top:100px",...)
}

#' Catch errors
#'
#' Catch errors and return alert panel in an existing div id.
#'
#' @param title Title of the alert
#' @param session Shiny session object
#' @param debug Boolean. Return also message as alert.
#' @param panelId Id of the output element
#' @export
mxCatch <- function(title,expression,session=shiny:::getDefaultReactiveDomain(),debug=TRUE,panelId="panelAlert",...){
  tryCatch({
    eval(expression)
  },error = function(e){
    session$output[[panelId]]<-renderUI({
      mxPanelAlert(
        "error",
        title,
        message=tagList(
          p(e$message),
          p(style="", paste("(",paste(e$call,collapse=" "),")"))
          ),
        ...
        )
    })
  },warning = function(w){
    session$output[[panelId]]<-renderUI({
      mxPanelAlert(
        "warning",
        title,
        message=tagList(
          p(w$message),
          p(style="",paste("(",paste(w$call,collapse=" "),")"))
          ),
        ...
        )
    })
  },message = function(m){
    if(debug){
      session$output[[panelId]]<-renderUI({
        mxPanelAlert(
          "warning",
          title,
          message=tagList(
            p(m$message),
            p(style="",paste("(",paste(m$call,collapse=" "),")"))
            ),
          ...
          )
      })
    }
  })   
}

#' Password input
#'
#' Create a password input.
#' 
#' @param inputId Input id
#' @param label Label to display
#' @export
pwdInput <- function(inputId, label) {
    tagList(
    tags$input(id = inputId,placeholder=label,class="mxLoginInput",type="password", value="")
    )
}

#' User name input
#' 
#' Create a username input
#' 
#' @param inputId Input id
#' @param label Label to display
#' @export
usrInput <- function(inputId, label) {
  tagList(
    tags$input(id = inputId, placeholder=label,class="mxLoginInput usernameInput", value="")
    )
}



#' Random name generator
#' 
#' Create a random name with optional prefix and suffix.
#' 
#' @param prefix Prefix. Default = NULL
#' @param suffix Suffix. Default = NULL
#' @param n Number of character to include in the random string
#' @return  Random string of letters, with prefix and suffix
#' @export
randomName <- function(prefix=NULL,suffix=NULL,n=20,sep="_"){
  prefix = subPunct(prefix,sep)
  suffix = subPunct(suffix,sep)
  rStr = paste(letters[round(runif(n)*24)],collapse="")
  str = c(prefix,rStr,suffix)
  paste(str,collapse=sep)
}

#' Substitute ponctiation and non-ascii character
#'
#' Take a string and convert to ascii string with optional transliteration ponctuation convertion. 
#'
#' @param str String to evaluate
#' @param sep Replace separator
#' @param rmTrailingSep Logical argument : no trailing separator returned
#' @param rmLeadingSep Logical argument : no leading separator returned
#' @param rmDuplicateSep Logical argument : no consecutive separator returned
#' @export
subPunct<-function(str,sep='_',rmTrailingSep=T,rmLeadingSep=T,rmDuplicateSep=T,useTransliteration=T){
  if(useTransliteration){
    str<-gsub("'",'',iconv(str, to='ASCII//TRANSLIT'))
  }
  res<-gsub("[[:punct:]]+|[[:blank:]]+",sep,str)#replace punctuation by sep
  res<-gsub("\n","",res)
  if(rmDuplicateSep){
    if(nchar(sep)>0){
      res<-gsub(paste0("(\\",sep,")+"),sep,res)# avoid duplicate
    }
  }
  if(rmLeadingSep){
    if(nchar(sep)>0){
      res<-gsub(paste0("^",sep),"",res)# remove trailing sep.
    }
  }
  if(rmTrailingSep){
    if(nchar(sep)>0){
      res<-gsub(paste0(sep,"$"),"",res)# remove trailing sep.
    }
  }
  res
}



#' Transfert postgis feature by sql query to sp object
#' @param dbInfo Named list with dbName,host,port,user and password.
#' @param query PostGIS spatial sql querry.
#' @return spatial object.
#' @export
dbGetSp <- function(dbInfo,query) {
  if(!require('rgdal')|!require(RPostgreSQL))stop('missing rgdal or RPostgreSQL')
  d <- dbInfo

  tmpTbl <- sprintf('tmp_table_%s',round(runif(1)*1e5))

  dsn <- sprintf("PG:dbname='%s' host='%s' port='%s' user='%s' password='%s'",
    d$dbname,d$host,d$port,d$user,d$password
    )

  drv <- dbDriver("PostgreSQL")

  con <- dbConnect(drv, dbname=d$dbname, host=d$host, port=d$port,user=d$user, password=d$password)

  tryCatch({

    sql <- sprintf("CREATE UNLOGGED TABLE %s AS %s",tmpTbl,query)

    res <- dbSendQuery(con,sql)

    nr <- dbGetInfo(res)$rowsAffected

    if(nr<1){

      warning('There is no feature returned.'); 

      return()

    }

    sql <- sprintf("SELECT f_geometry_column from geometry_columns WHERE f_table_name='%s'",tmpTbl) 


    geo <- dbGetQuery(con,sql)

    if(length(geo)>1){
      tname <- sprintf("%s(%s)",tmpTbl,geo$f_geometry_column[1])
    }else{
      tname <- tmpTbl;
    }
    out <- readOGR(dsn,tname)

    on.exit({
      sql <- sprintf("DROP TABLE %s",tmpTbl)
      dbSendQuery(con,sql)
      dbClearResult(dbListResults(con)[[1]])
      dbDisconnect(con) 
    })

    return(out)
  })

}


#' Geojson from postGIS base
#' @param dbInfo Named list with dbName,host,port,user and password
#' @param query PostGIS spatial sql querry.
#' @return geojson list
#' @export
dbGetGeoJSON<-function(dbInfo,query,fromSrid="4326",toSrid="4326"){
  # NOTE: check package geojsonio for topojson and geojson handling.
  # https://github.com/ropensci/geojsonio/issues/61
  d <- dbInfo
  dsn <- sprintf("PG:dbname='%s' host='%s' port='%s' user='%s' password='%s'",
    d$dbname,d$host,d$port,d$user,d$password
    )
  tmp <- paste0(tempfile(),".geojson")
  system(sprintf("ogr2ogr -f GeoJSON '%s' '%s' -sql '%s' -s_srs 'EPSG:%4$i' -t_srs 'EPSG:%5$i'",tmp,dsn,query,fromSrid,toSrid))
  return(jsonlite::fromJSON(tmp))
}
#' Get layer extent
#' @param dbInfo Named list with dbName,host,port,user and password
#' @param table Table/layer from which extract extent
#' @param geomColumn set geometry column
#' @return extent
#' @export
dbGetLayerExtent<-function(dbInfo=NULL,table=NULL,geomColumn='geom'){
  if(is.null(dbInfo) || is.null(table)) stop('Missing arguments')
 
    if(table %in% mxDbListTable(dbInfo)){

     q <- sprintf("SELECT ST_Extent(%s) as table_extent FROM %s;",geomColumn,table)

      ext <- mxDbGetQuery(dbInfo,q)[[1]] %>% 
      strsplit(split=",")%>%
      unlist() %>%
      gsub("[a-z,A-Z]|\\(|\\)","",.) %>%
      strsplit(split="\\s") %>%
      unlist() %>%
      as.numeric() %>%
      as.list()
      names(ext)<-c("lng1","lat1","lng2","lat2")
      return(ext)

    }
}


#' @export
dbGetValByCoord <- function(dbInfo=NULL,table=NULL,column=NULL,lat=NULL,lng=NULL,geomColumn="geom",srid="4326",distKm=1){
  if(
    noDataCheck(dbInfo) ||
    noDataCheck(table) || 
    noDataCheck(column) || 
    noDataCheck(lat) ||
    noDataCheck(lng) ||
    isTRUE(column=='gid')
    ){
    return()
  }else{

    timing<-system.time({
      sqlPoint <- sprintf("'SRID=%s;POINT(%s %s)'",srid,lng,lat)
      sqlWhere <- sprintf(
        paste(
          "with index_query as (select st_distance(%s, %s) as distance, %s from %s order by %s <#> %s limit 10)",
          "select %s from index_query where distance < 0.1 order by distance limit 1;"
          ),
        geomColumn,sqlPoint,column,table,geomColumn,sqlPoint,column
        )
      res <- mxDbGetQuery(dbInfo,sqlWhere)
    })
    return(
      list(
        result=res,
        latitude=lat,
        longitude=lng,
        timing=timing
        )
      ) 
  }
}




#' Get variable summary
#'
#' @param dbInfo Named list with dbName,host,port, user and password
#' @param table Table/layer from which extract extent
#' @param column Column/Variable on wich extract summary
#' @export
  dbGetColumnInfo<-function(dbInfo=NULL,table=NULL,column=NULL){

    if(noDataCheck(dbInfo) || noDataCheck(table) || noDataCheck(column) || isTRUE(column=='gid'))return() 


      timing<-system.time({

      q <- sprintf(
            "SELECT attname 
            FROM pg_attribute 
            WHERE attrelid = 
            (SELECT oid 
              FROM pg_class 
              WHERE relname = '%s'
              ) 
            AND attname = '%s';"
            ,table,
            column
            )

        columnExists <- nrow( mxDbGetQuery(dbInfo,q) ) > 0 

        if(!columnExists){
          message(paste("column",column," does not exist in ",table))
          return()
        }

        nR <- mxDbGetQuery(dbInfo,sprintf(
            "SELECT count(*) 
            FROM %s 
            WHERE %s IS NOT NULL"
            ,table
            ,column
            )
          )[[1]]

        nN <- mxDbGetQuery(dbInfo,sprintf(
            "SELECT count(*) 
            FROM %s 
            WHERE %s IS NULL"
            ,table
            ,column
            )
          )[[1]]
        nD <- mxDbGetQuery(dbInfo,sprintf(
            "SELECT COUNT(DISTINCT(%s)) 
            FROM %s 
            WHERE %s IS NOT NULL"
            ,column
            ,table
            ,column
            )
          )[[1]]

        val <- mxDbGetQuery(dbInfo,sprintf("
            SELECT DISTINCT(%s) 
            FROM %s 
            WHERE %s IS NOT NULL"
            ,column
            ,table
            ,column
            ),stringAsFactors=T)[[1]]
      })


      scaleType <- ifelse(is.factor(val) || is.character(val),'discrete','continuous')
     
      return(
        list(
          'table' = table,
          'column' = column,
          'nDistinct'=nD,
          'nRow'=nR,
          'nNa'=nN,
          'scaleType'=scaleType,
          'dValues'=val,
          'timing'=timing
          )
        ) 
  }

















#' Get layer center
#' 
#' Compute the union of all geometry in a given layer and return the coordinate of the centroid.
#' 
#' @param dbInfo Named list with dbName,host,port,user and password
#' @param table Table/layer from which extract extent
#' @param geomColumn set geometry column
#' @return extent
#' @export
dbGetLayerCentroid<-function(dbInfo=NULL,table=NULL,geomColumn='geom'){
  if(is.null(dbInfo) || is.null(table)) stop('Missing arguments')
  
  tryCatch({
    if(table %in% dbListTables(con)){
      
      query <- sprintf(
        "SELECT ST_asText(ST_centroid(ST_union(%s))) 
        FROM %s 
        WHERE 
        ST_isValid(%s) = true;"
        ,geomColumn
        ,table
        ,geomColumn
        )

      
      mxDbGetQuery(dbInfo,query)[[2]] %>%
      strsplit(split=" ")%>%
      unlist()%>%
      gsub("[a-z,A-Z]|\\(|\\)","",.)%>%
      strsplit(split="\\s")%>%
      unlist()%>%
      as.numeric()%>%
      as.list()
      names(ext)<-c("lng","lat")

    dbDisconnect(con)
      return(ext)
    }
  },finally={
    dbDisconnect(con)
  })
}

#' Get query extent, based on a pattern matching (character)
#' 
#' Search for a value in a  column (character data type) and return the extent if something is found.
#'
#' @param dbInfo Named list with dbName,host,port,user and password
#' @param table Table/layer from which extract extent
#' @param geomColumn set geometry column
#' @return extent
#' @export
dbGetFilterCenter<-function(dbInfo=NULL,table=NULL,column=NULL,value=NULL,geomColumn='geom',operator="="){
  if(is.null(dbInfo) || is.null(table)) print("missing arguments in dbGetFilterCenter")

  if(table %in% mxDbListTable(dbInfo)){
    valueOrig <- gsub("'","''",value)
    valueEscape <- paste0("(E",paste0("\'",valueOrig,"\'",collapse=","),")")
    if(length(value)>1){
      operator <- "in"
    }

    q = sprintf("
      SELECT ST_Extent(%1$s) 
      FROM (SELECT %1$s FROM %2$s WHERE %3$s %5$s %4$s ) t
      WHERE ST_isValid(%1$s)",
      geomColumn,
      table,
      column,
      valueEscape,
      operator
      )

    ext <- mxDbGetQuery(dbInfo,q)[[1]]

    if(noDataCheck(ext))return(NULL)
    res <- ext %>%
    strsplit(split=",")%>%
    unlist()%>%
    strsplit(split=" ")%>%
    unlist()%>%
    gsub("[a-z,A-Z]|\\(|\\)","",.)%>%
    as.numeric()
    names(res)<-c('lng1', 'lat1', 'lng2', 'lat2')

    return(res)
  }

}



#' Create a bootstrap accordion 
#'
#' Create a bootstrap accordion element, based on a named list.
#'
#' @param id Accordion group ID
#' @param style Additional style. 
#' @param show Vector of item number. Collapse all item except those in this list. E.g. c(1,5) will open items 1 and 5 by default. 
#' @param itemList Nested named list of items, containing title and content items. E.g. list("foo"=list("title"="foo","content"="bar"))
#' @examples 
#' amAccordionGroup(id='superTest',
#'  itemList=list(
#'    'a'=list('title'='superTitle',content='acontent'),
#'    'b'=list('title'='bTitle',content='bContent'))
#'  )
#' @export
mxAccordionGroup<-function(id,style=NULL,show=NULL,itemList){
  if(is.null(style)) style <- ""
  cnt=0
  contentList<-lapply(itemList,function(x){
    cnt<<-cnt+1
    ref<-paste0(subPunct(id,'_'),cnt)
    showItem<-ifelse(cnt %in% show,'collapse in','collapse')
    stopifnot(!is.list(x) || !is.null(x$title) || !char(x$title)<1 || !is.null(x$content) || !nchar(x$content)<1)
    if(is.null(x$condition))x$condition="true"
    div(style=style,class=paste("panel panel-default",x$class),`data-display-if`=x$condition,
      div(class="panel-heading mx-panel-header",
        h4(class="panel-title",
          a('data-toggle'="collapse", 'data-parent'=paste0('#',id),href=paste0("#",ref),x$title)
          )
        ),
      div(id=ref,class=paste("panel-collapse",showItem),
        div(class="panel-body mx-panel-content",x$content)
        )
      )
  })

  return(div(class="panel-group",id=id,
      contentList
      ))
}

#' Load external ui file value in shiny app
#'
#' Shortcut to load external shiny ui file
#'
#' @param path Path to the file
#' @export
loadUi<-function(path){
  source(path,local=TRUE)$value
}


#' Retrieve map views table 
#'
#' Get a list of available map-x views in given table, e.g. mx_views 
#'
#' @param dbInfo Named list with dbName,host,port, user and password
#' @param table Table name containing views info
#' @param validated Boolean filter validated dataset. Default = TRUE
#' @param archived Boolean filter to get archived data. Default =FALSE
#' @param country ISO 3 code to filter country. 
#' @export
mxGetViewsTable <- function(dbInfo=NULL, table="mx_views",validated=TRUE,archived=FALSE,country="AFG"){
    
    country = paste0("'",country,"'",collapse=",")

    if(isTRUE(table %in% mxDbListTable(dbInfo))){

      q <- sprintf(
        "SELECT * FROM %s 
        WHERE validated is %s 
        AND archived is %s 
        AND country 
        IN (%s)"
        ,table
        ,validated
        ,archived
        ,country
        )

      res <- mxDbGetQuery(dbInfo,q)

      return(res)

    }else{
      mxDebugMsg(
        paste(
          "mxGetViewsList: table"
          ,table
          ," content requested, but not found in db."
          )
        )
    }


}


#' Custom file input 
#'
#' Default shiny fileInput has no option for customisation. This function allows to fully customize file input using the label tag.
#'
#' @param inputId id of the file input
#' @param label Label for the input
#' @param fileAccept List of accepted file type. Could be extension.
#' @param multiple  Boolean. Allow multiple file to be choosen. Doesn't work on all client.
#' @export
mxFileInput<-function (inputId, label, fileAccept=NULL, multiple=FALSE){
  inputTag<-tags$input(
    type='file',
    class='upload',
    accept=paste(fileAccept,collapse=','),
    id=inputId,
    name=inputId)
  if(multiple) inputTag$attribs$multiple='multiple'
  spanTag <- tags$span(label)
  inputClass <- tags$label(
    class=c('btn-browse btn btn-default'),
    id=inputId,
    spanTag,
    inputTag
    )
  tagList(inputClass,
    tags$div(id = paste(inputId,"_progress", sep = ""), 
      class = "progress progress-striped active shiny-file-input-progress",
      tags$div(class = "progress-bar"), tags$label()))
}

#' Toggle disabling of given button, based on its id.
#'
#' Action or other button can be disabled using the attribute "disabled". This function can update a button state using this method.
#'
#' @param id Id of the button. 
#' @param session Shiny session object.
#' @param disable State of the button
#' @export
mxActionButtonState <- function(id,session=shiny:::getDefaultReactiveDomain(),disable=TRUE) {
  res <- list(
    id = id,
    disable = disable 
    )
  session$sendCustomMessage(
    type="mxSetButonState",
    res
    )
}


#' Send command on remote server through ssh
#'
#' Allow sending command on a remote server, e.g. Vagrant machine, using ssh. 
#'
#' @param host Host
#' @param user User
#' @param port Port
#' @param cmd Command to send
#' @param vagrant Boolean. If TRUE, use ssh config file. E.g. vagrant ssh-config > sshConfig
#' @export
remoteCmd <- function(host=NULL,user=NULL,port=NULL,cmd=NULL,vagrant=TRUE,sshConfig="settings/sshConfig"){
  res=NULL
  if(!is.null(cmd)){
    if(vagrant){
      res =  system(sprintf("ssh %s -F %s -C \"%s\"",host,sshConfig,cmd),intern=TRUE)

    }else{

      res =  system(sprintf("ssh -p %s %s@%s %s",port,user,host,cmd),intern=TRUE)
    }
  }
  return(res)
}

#' Write spatial data frame to postgis
#'
#' Convert spatial data.frame to postgis table. Taken from https://philipphunziker.wordpress.com/2014/07/20/transferring-vector-data-between-postgis-and-r/
#'
#' @param con PostgreSQL connection
#' @param spatial.df  Spatial  data frame object
#' @param schemaname Target schema table
#' @param tablename Target table name
#' @param overwrite Overwrite if exists
#' @param keyCol Set new primary key
#' @param srid Set the epsg code / SRID
#' @param geomCol Set the name of the geometry column
dbWriteSpatial <- function(con, spatial.df, schemaname="public", tablename, overwrite=FALSE, keyCol="gid", srid=4326, geomCol="geom") {

  on.exit(dbDisconnect(con))
  
  library(rgeos)

  # Create well known text and add to spatial DF
  spatialwkt <- writeWKT(spatial.df, byid=TRUE)
  spatial.df$wkt <- spatialwkt

  # Add temporary unique ID to spatial DF
  spatial.df$spatial_id <- 1:nrow(spatial.df)

  # Set column names to lower case
  names(spatial.df) <- tolower(names(spatial.df))

  # Upload DF to DB
  data.df <- spatial.df@data
  rv <- dbWriteTable(con, c(schemaname, tablename), data.df, overwrite=overwrite, row.names=FALSE)

  # Create geometry column and clean up table
  schema.table <- paste(schemaname, ".", tablename, sep="")
  query1 <- sprintf("ALTER TABLE %s ADD COLUMN %s GEOMETRY;", schema.table, geomCol)
  query2 <- sprintf("UPDATE %s SET %s = ST_GEOMETRYFROMTEXT(t.wkt) FROM %s t  WHERE t.spatial_id = %s.spatial_id;",
    schema.table, geomCol, schema.table, schema.table)
  query3 <- sprintf("ALTER TABLE %s DROP COLUMN spatial_id;",schema.table)
  query4 <- sprintf("ALTER TABLE %s DROP COLUMN wkt;",schema.table)
  query5 <- sprintf("SELECT UpdateGeometrySRID('%s','%s','%s',%s);",schemaname,tablename,geomCol,srid)


  er <- dbGetQuery(con, statement=query1)
  er <- dbGetQuery(con, statement=query2)
  er <- dbGetQuery(con, statement=query3)
  er <- dbGetQuery(con, statement=query4)
  er <- dbGetQuery(con, statement=query5)




  if(!is.null(keyCol)){
    query6 <- sprintf("ALTER TABLE %s ADD COLUMN %s SERIAL PRIMARY KEY;", schema.table, keyCol)
    er <- dbGetQuery(con, statement=query6)
  }



  return(TRUE)
}


#' Add palette to map-x style list
#'
#' Update a style list with a palette, using the defined scale type : continuous or discrete. 
#'
#' @param sty map-x style
#' @param pal name of palette to use
#' @export
addPaletteFun <- function(sty,pal){
  res <- try(silent=TRUE,{
  if( sty$scaleType == "continuous" ) { 
    sty$paletteFun <- colorNumeric(
      palette = sty$palette,
      domain = sty$values
      )  
  }else{
    sty$paletteFun <- colorFactor(
      palette = sty$palette,
      sty$values
      )
  }
    })
  if(class(res) == "try-error" ){
    stop(res)
  }
  return(sty)
}

#' Apply map-x style to existing vector tiles
#'
#' When leafletvt handle a vector tile source, a lealflet object is stored in leafletvtId, but no style is applied. Default is transparent. We add a style function after that the layer is fully loaded using this function. The style function is also stored alongside the leaflet object in leafletId under the name "vtStyle".
#'
#' @param session Shiny session object
#' @param style map-x style
#' @export 
mxSetStyle<-function(session=shiny:::getDefaultReactiveDomain(),style,mapId="mapxMap"){
  tit <- style$title
  col <- style$colors
  pal <- style$paletteFun
  val <- style$values
  var <- style$variable
  lay <- style$layer
  opa <- style$opacity
  sze <- style$size
  grp <- style$group
  leg <- style$hideLegends
  bnd <- style$bounds
  mxd <- style$mxDateMax
  mnd <- style$mxDateMin
  unt <- style$variableUnit
  
  # handle min and max date if exists.
  if(noDataCheck(mnd))mnd<-as.POSIXlt(mxConfig$minDate)
  if(noDataCheck(mxd))mxd<-as.POSIXlt(mxConfig$maxDate)

  # debug messages
  mxDebugMsg("Begin style")
  start <- Sys.time()
  
  # set id of legends based on style group id.
  legendId <- sprintf("%s_legends",grp)
  legendClass <- sprintf("info legend %s",legendId)
  proxyMap <- leafletProxy(mapId)
 

  # label format 


  # If no title, take the layer name.
  if(noDataCheck(tit))tit<-lay

  # delete old legend.
  proxyMap %>% removeControl(layerId=legendId)
  # sometimes this does not work. Double removal.
  mxRemoveEl(class=legendClass)
  if(isTRUE(!leg)){
    if(!noDataCheck(unt)){
      labFor<-labelFormat(suffix=unt)
    }else{
      labFor<-labelFormat()
    }
    proxyMap %>%
    addLegend(position="bottomright",
      labFormat=labFor,
      pal=pal,
      values=val,
      layerId=
      legendId,
      class=legendClass,
      title=tit
      )
  }

  names(col) <- val
  sList = list(
    colorsPalette = as.list(col),
    dataColum = var,
    opacity = opa,
    size = sze,
    mxDateMin = as.numeric(as.POSIXlt(mnd)),
    mxDateMax = as.numeric(as.POSIXlt(mxd))
    )

  # Apply style
  #jsSty <- sprintf("mxSetStyle('%1$s',%2$s,'%3$s',false)",grp,sList,lay)



  session$sendCustomMessage(
    type="setStyle",
    list(
      group=grp,
      layer=lay,
      style=sList
      )
    )
  # print timing
  stop <- Sys.time() - start
  mxDebugMsg(paste("End style. Timing=",stop))
  cat(paste(paste0(rep("-",80),collapse=""),"\n"))
}




#' Custom select input
#'
#' Custom select input without label.
#'
#' @param inputId Element id
#' @param choices List of options
#' @param select Value selected by default
#' @export
mxSelectInput<-function(inputId,choices=NULL,selected=NULL){
  opt <- NULL
  if(!noDataCheck(choices)){
    if(noDataCheck(selected))selected=choices[1]
    opt <- HTML(sprintf("<option value=%s>%s</option>",choices,choices))
  }
  tagList(
    div(class="form-control form-group shiny-input-container mx-select-input-container",
        tags$select(id=inputId,class="form-control shiny-bound-input  mx-select-input",opt)
      )
    )
}


#' Control ui access
#'  
#' UI  manager based on login info
#'
#' @param logged Boolean. Is the user logged in ?
#' @param roleNum Numeric. Role in numeric format
#' @param roleLowerLimit Numeric. Minumum role requirement
#' @param uiDefault TagList. Default ui.
#' @param uiRestricted TagList. Restricted ui.
#' @export
mxUiAccess <- function(logged,roleNum,roleLowerLimit,uiDefault,uiRestricted){
  uiOut <- uiDefault
  if(isTRUE(logged) && is.numeric(roleNum)){
    if(noDataCheck(roleLowerLimit))roleLowerLimit=0
    if(roleNum>=roleLowerLimit){
      uiOut<-uiRestricted
    }
  }
  return(uiOut)
}

#' Control visbility of elements
#' 
#' Display or hide element by id, without removing element AND without having element's space empty in UI. This function add or remove mx-hide class to the element.
#'
#' @param session Shiny session
#' @param id Id of element to enable/disable 
#' @param enable Boolean. Enable or not.
#' @export
mxUiEnable<-function(session=shiny:::getDefaultReactiveDomain(),id=NULL,class=NULL,enable=TRUE,classToRemove="mx-hide"){


  if(noDataCheck(enable)){
    enable <- FALSE
  }


  prefix <- ifelse(is.null(id),".","#")

  if(is.null(id)){
    element <- class
  }else{
    element <- id
  } 

  element <- paste(paste0(prefix,element),collapse=",")
  res = list(
    enable=enable,
    element=element,
    classToRemove=classToRemove
    )
  session$sendCustomMessage(
    type="mxUiEnable",
    res
    )
}


#' Control ui access
#' 
#' Use mxConfig$roleVal list to check if the curent user's role name can access to the given numeric role.
#' 
#' @param logged Boolean. Is the user logged in ?
#' @param roleName Character. Role in numeric format
#' @param roleLowerLimit Numeric. Minumum role requirement
#' @export
mxAllow <- function(logged,roleName,roleLowerLimit){
  allow <- FALSE
  if(noDataCheck(roleName))return(FALSE)
  roleNum = mxConfig$rolesVal[[roleName]]

  if(isTRUE(logged) && is.numeric(roleNum)){
    if(noDataCheck(roleLowerLimit))roleLowerLimit=0
    if(roleNum>=roleLowerLimit){
      allow <- TRUE
    }
  }
  return(allow)
}




mxToggleMapPanels <- function(modeSelected){
  modeAvailable <- mxConfig$mapPanelModeAvailable

  if(!isTRUE(modeSelected %in% modeAvailable)){
     stop(sprintf("Map panel mode % not available. Set it in mxConfig",modeSelected))
  }
  
  stopifnot(modeSelected %in% modeAvailable)
  mS <- modeSelected
  mA <- modeAvailable
  mD <- mA[!mA %in% mS]
  mxUiEnable(class=mS,enable=TRUE)
  mxUiEnable(class=mD,enable=FALSE)
}


#' Set a checkbox button with custom icon.
#' 
#' Create a checkbox input with a select icon.
#'
#' @param id Id of the element
#' @param icon Name of the fontawesome icon. E.g. cog, times, wrench
#' @export
mxCheckboxIcon <- function(id,idLabel,icon,display=TRUE){
  visible <- "display:inline-block"
  if(!display)visible <- "display:none"
  tagList(
    div(id=idLabel,class="checkbox",style=paste(visible,';float:right;'),
      tags$label(
        tags$input(type="checkbox",class="vis-hidden",id=id),
        tags$span(icon(icon))
        )
      )
    )
}

#' remove element by class or id
#' @param session default shiny session
#' @param class class name to remove
#' @param id id to remove
#' @export
mxRemoveEl <- function(session=getDefaultReactiveDomain(),class=NULL,id=NULL){
 if(is.null(class) && is.null(id))return()
sel <-ifelse(is.null(class),paste0('#',id),paste0('.',class))

res <- list(
  element = sel
  )

session$sendCustomMessage(
  type="mxRemoveEl",
  res
  )

}

#' Set ioRange slider for opacity
#' 
#' @param id Id of the slider
#' @param opacity Default opacity
#' @export
mxSliderOpacity <- function(id,opacity){
  tagList(
    tags$div(class="slider-date-container",
      tags$div(type="text",id=sprintf("slider-opacity-for-%s",id)),
      tags$script(sprintf(
          "
          $slider = $('#slider-opacity-for-%1$s');
          $slider.ionRangeSlider({
            min: 0,
            max: 1,
            from: %2$s,
            step:0.1,
            onChange: function (data) {
              setOpacityForId('%1$s',data.from)
            }
          });",
          id,
          opacity
          )
        )
      )
    ) 
}
#' Set ioRange slider for time slider
#' 
#' @param id Id of the slider
#' @param min Minimum js unix date in milisecond 
#' @param max Maxmimum js unix date in milisecond 
#' @param lay Layer name
#' @export 
mxTimeSliderDouble <-function(id,min,max,lay){
  tagList(
    tags$div(class="slider-date-container",
      tags$input(type="text",id=sprintf("slider-for-%s",id)),
      tags$script(sprintf(
          "
          $slider = $('#slider-for-%3$s');
          $slider.ionRangeSlider({
            type: 'double',
            min: %1$s,
            max: %2$s,
            from: %1$s,
            to: %2$s,
            step:1000*60*60*24 ,
            prettify: function (num) {
              var m = moment(num)
              return m.format('YYYY-MM-DD');
            },
            onChange: function (data) {
              //setRange('%3$s',data.from/1000,data.to/1000)
              mxSetRange('%3$s',data.from/1000,data.to/1000,'%4$s')
            }
          });",
          min,
          max,
          id,
          lay
          )
        )
      )
    ) 
}

#' Set ioRange slider for time slider
#' 
#' @param id Id of the slider
#' @param min Minimum js unix date in milisecond 
#' @param max Maxmimum js unix date in milisecond 
#' @param lay Layer name
#' @export 
mxTimeSlider <- function(id,min,max,lay){
  tagList(
    tags$div(class="slider-date-container",
      tags$div(type="text",id=sprintf("slider-for-%s",id)),
      tags$script(sprintf(
          "
          $slider = $('#slider-for-%3$s');
          $slider.ionRangeSlider({
            /*type: 'double',*/
            min: %1$s,
            max: %2$s,
            from: %1$s,
            to: %2$s,
            step:1000*60*60*24 ,
            prettify: function (num) {
              var m = moment(num)
              return m.format('YYYY-MM-DD');
            },
            onChange: function (data) {
              //setRange('%3$s',data.from/1000,data.to/1000)
              mxFilterDate('%3$s',data.from/1000,'%4$s')
            }
          });",
          min,
          max,
          id,
          lay
          )
        )
      )
    ) 
}






#' encode in base64
mxEncode <- function(text){
  base64enc::base64encode(charToRaw(as.character(text)))
}

mxDecode <- function(base64text){
  rawToChar(base64enc::base64decode(base64text))
}




#' Update text by id
#'
#' Search for given id and update content. 
#' 
#' @param session Shiny session
#' @param id Id of the element
#' @param text New text
#' @export
mxUpdateText<-function(session=shiny:::getDefaultReactiveDomain(),id,text=NULL,ui=NULL,addId=FALSE){
  if(is.null(text) && is.null(ui)){
    return(NULL)
  }else{
    if(is.null(ui)){
    textb64 <- mxEncode(text)
      val=list(
        id = id,
        txt = textb64,
        addId = addId
        )
      session$sendCustomMessage(
        type="updateText",
        val
        )
    }else{
   session$output[[id]] <- renderUI(ui)
  }
  }
}


#' Update value by id
#'
#' Search for given id and update value. 
#' 
#' @param session Shiny session
#' @param id Id of the element
#' @param  value New text value
#' @export
mxUpdateValue <- function(session=shiny:::getDefaultReactiveDomain(),id,value){
  if(is.null(value)){
    return(NULL)
  }else{

    res <- list(
      id=id,
      val=value
      )
    session$sendCustomMessage(
      type="mxUpdateValue",
      res
      )
  }
}





#' Get query result from postgresql
#'
#' Shortcut to create a connection, get the result of a query and close the connection, using a dbInfo list. 
#'
#' @param dbInfo Named list with dbName,host,port,user and password
#' @param SQL query
#' @export
mxDbGetQuery <- function(dbInfo,query,stringAsFactors=F){
  tryCatch({
    d <- dbInfo
    drv <- dbDriver("PostgreSQL")
    con <- dbConnect(drv, dbname=d$dbname, host=d$host, port=d$port,user=d$user, password=d$password)
    suppressWarnings({
    res <- dbGetQuery(con,query,stringAsFactors=stringAsFactors)
    })

    dbDisconnect(con)
    on.exit({ 
    dbDisconnect(con)
    mxDbClearAll(dbInfo)
    })
    # return
    return(res)
  },
    finally={})
}


mxDbClearAll <- function(dbInfo){
  d <- dbInfo
  drv <- dbDriver("PostgreSQL")
  cons <- dbListConnections(drv)
  if(length(cons)>0){
    lapply(cons,function(x){
      nR <- dbListResults(x)
      if(length(nR)>0){
        lapply(nR,dbClearResult)
      }
      dbDisconnect(x)
  })
  }
}




#' List existing table from postgresql
#'
#' Shortcut to create a connection, get the list of table and close the connection, using a dbInfo list. 
#'
#' @param dbInfo Named list with dbName,host,port,user and password
#' @export
mxDbListTable<- function(dbInfo){
  tryCatch({
    d <- dbInfo
    drv <- dbDriver("PostgreSQL")
    con <- dbConnect(drv, dbname=d$dbname, host=d$host, port=d$port,user=d$user, password=d$password)
    res <- dbListTables(con)

    dbDisconnect(con)
    return(res)
  },finally=if(exists('con'))dbDisconnect(con)
  )
}

#' List existing column from postgresql table
#'
#' Shortcut to create a connection, get the list of column and close the connection, using a dbInfo list. 
#'
#' @param dbInfo Named list with dbName,host,port,user and password
#' @export
mxDbListColumns <- function(dbInfo,table){
  tryCatch({
    d <- dbInfo
    drv <- dbDriver("PostgreSQL")
    con <- dbConnect(drv, dbname=d$dbname, host=d$host, port=d$port,user=d$user, password=d$password)
    res <- dbListFields(con,table)

    dbDisconnect(con)
    return(res)
  },finally=if(exists('con'))dbDisconnect(con)
  )
}






#' Add data to db
#'
#' 
#'
mxDbAddData <- function(dbInfo,data,table){

  stopifnot(class(data)=="data.frame")
  stopifnot(class(table)=="character")

  tryCatch({
    d <- dbInfo
    drv <- dbDriver("PostgreSQL")
    con <- dbConnect(drv, dbname=d$dbname, host=d$host, port=d$port,user=d$user, password=d$password)
    res <- dbListTables(con)
    tExists <- isTRUE(table %in% res)
    nExists <- FALSE

    if(tExists){
      tNam <- names(table)
      rNam <- dbListFields(con,table)
      nExists <- all(tNam %in% rNam)
      wText <- sprintf("mxDbAddData: remote table %1$s has fields: '%2$s', table to append: '%3$s'",
        table,
        paste(rNam,collapse="; "),
        paste(tNam,collapse="; ")
        )
      if(!nExists){
        stop(wText)
      }
    }

    dbWriteTable(con,name=table,value=data,append=nExists,row.names=F)

    dbDisconnect(con)
  },finally=if(exists('con'))dbDisconnect(con)
  )
}

mxDbUpdate <- function(dbInfo,table,column,idCol="id",id,value){
    
   query <- sprintf("
      UPDATE %1$s
      SET %2$s='%3$s'
      WHERE %4$s='%5$s'",
      table,
      column,
      value,
      idCol,
      id
      )

    res <- mxDbGetQuery(dbInfo,query)

    return(res)
}





#' Create random secret
#'
#' Get a random string of letters and hash it.
#'
#' @param n Number of input letter for the MD5 hash
#' @export
mxCreateSecret =  function(n=20){
  stopifnot(require(digest))
  digest::digest(paste(letters[round(runif(n)*24)],collapse=""))
}


#' Save named list of value into cookie
#'
#' Note : don't use this for storing sensitive data, unless you have a trusted network.
#'
#' @param session Shiny session object. By default: default reactive domain.
#' @param cookie Named list holding paired cookie value. e.g. (list(whoAteTheCat="Alf"))
#' @param nDaysExpires Integer of days for the cookie expiration
#' @return NULL
#' @export
mxSetCookie <- function(session=getDefaultReactiveDomain(),cookie=NULL,nDaysExpires=NULL,deleteAll=FALSE){

  cmd = list()
  cmd$domain <- session$url_hostname
  cmd$path <- session$url_pathname
  cmd$deleteAll <- deleteAll
  cmd$cookie <- cookie
  cmd$expiresInSec <- nDaysExpires * 86400
 
  session$sendCustomMessage(
    type="mxSetCookie",
    cmd
    )
}



#' Overlaps analysis 
#' 
#' Use a mask to get overlaps over a layer
#' @export
mxAnalysisOverlaps <- function(dbInfo,inputBaseLayer,inputMaskLayer,outName,dataOwner="mapxw",sridOut=4326,varToKeep="gid"){

  msg=character(0)
  if(!outName %in% mxDbListTable(dbInfo)){

    varToKeep <- paste0(sprintf("%s.%s",inputBaseLayer,varToKeep),collapse=",")
    createTable = sprintf("
      create table %1$s as SELECT %4$s, 
      ST_Multi(ST_Buffer(ST_Intersection(%3$s.geom, %2$s.geom),0.0)) As geom
      FROM %3$s
      INNER JOIN %2$s
      ON ST_Intersects(%3$s.geom, %2$s.geom)
      WHERE Not ST_IsEmpty(ST_Buffer(ST_Intersection(%3$s.geom, %2$s.geom),0.0));
      ALTER TABLE %1$s
      ALTER COLUMN geom TYPE geometry(MultiPolygon, %5$i) 
      USING ST_SetSRID(geom,%5$i);
      ALTER TABLE %1$s OWNER TO %6$s;
      ALTER TABLE %1$s ADD COLUMN gid BIGSERIAL PRIMARY KEY;
      ",
      outName,
      inputBaseLayer,
      inputMaskLayer,
      varToKeep,
      sridOut,
      dataOwner
      )

    mxDbGetQuery(dbInfo,createTable) 
  }
  }


#' Create a formated list of available palettes
#' @export
mxCreatePaletteList <- function(palettes){
  pals <- palettes
  # Get palettes names
  colsPals <- row.names(pals)
  # create UI visible names 
  palsName <- paste(
    colsPals,
    " (n=",pals$maxcolors,
    "; cat=",pals$category,
    "; ", ifelse(pals$colorblind,"cb=ok","cb=warning"),
    ")",sep="")
  # put then together
  names(colsPals) <- palsName
  # return
  return(colsPals)

}


#' Create a formated list of country center from eiti countries table
#' @export
mxEitiGetCountryCenter <- function(eitiCountryTable){
  # Country default coordinates and zoom
  iso3codes <- eitiCountryTable$code_iso_3
  # Extract country center
  countryCenter <- lapply(
    iso3codes,function(x){
      res=eitiCountryTable[iso3codes==x,c('lat','lng','zoom')]
      res
    }
    )
  # set names
  names(countryCenter) <- iso3codes
  # return
  return(countryCenter)
}


#' Create a formated list for selectize input from eiti countries table
#' @export
mxEitiGetCountrySelectizeList <- function(eitiCountryTable){
  eitiCountryTable$map_x_pending <- as.logical(eitiCountryTable$map_x_pending)
  eitiCountryTable$name_ui <- paste(eitiCountryTable$name_un,'(',eitiCountryTable$name_official,')')
  countryList <- list(
    "completed" = NULL,
    "pending"= as.list(eitiCountryTable[eitiCountryTable$map_x_pending,"code_iso_3"])  ,
    "potential"= as.list(eitiCountryTable[!eitiCountryTable$map_x_pending,"code_iso_3"])
    )
  names(countryList$pending) = eitiCountryTable[eitiCountryTable$map_x_pending,"name_ui"]
  names(countryList$potential) = eitiCountryTable[!eitiCountryTable$map_x_pending,"name_ui"]

  return(countryList)
}

#' Create WDI indicators list
#' @export
mxGetWdiIndicators <- function(){
  require(WDI)
  wdiIndicators <- WDIsearch()[,'indicator']
  names(wdiIndicators) <- WDIsearch()[,'name']
  wdiIndicators
}


#' Reset all value in a reactiveValues object
#' @param reaciveObj Reactive values object
#' @export
   reactiveValuesReset <-function(reactiveObj,resetValue=""){
     rList <- names(reactiveValuesToList(reactiveObj))
     for(n in rList){
     reactiveObj[[n]]<-resetValue
     }
    }

#' Set zoom button options
#' @param map Leaflet map object
#' @param butonOptions List of  Leaflet options for zoom butons. E.g. list(position="topright") 
#' @param removeButton Boolean. Remove the zoom button.
#' @param
setZoomOptions <- function(map,buttonOptions=list(),removeButton=FALSE){ 
  stopifnot(require(leaflet))
  invokeMethod(map,NULL,'setZoomOptions',buttonOptions,removeButton)
}



#' Test if a text exists, update a output ui item
#' @param textTotest text to test against rules
#' @param existingTexts  Vector of existing text
#' @param idTextValidation Id of the ui element to update (id=example -> uiOutput("example"))
#' @param minChar Minimum character length
#' @param testForDuplicate Boolean test for duplicate.
#' @param testForMinChar Boolean test for minimum number of character
#' @param displayNameInValidation Boolean add text in validation text
#' @return boolean : valid or not
#' @export
mxTextValidation <- function(textToTest,existingTexts,idTextValidation,minChar=5,testForDuplicate=TRUE,testForMinChar=TRUE,displayNameInValidation=TRUE){

  if(isTRUE(length(textToTest)>1)){
    stop("mxTextValidation only validate one input item")
  }

  isValid <- FALSE
  isDuplicate <- FALSE
  isTooShort  <- FALSE
  err <- character(0)

  if(testForDuplicate){
    itemExists <- isTRUE(tolower(textToTest) %in% tolower(existingTexts))
  }
  if(testForMinChar){
    itemTooShort <- isTRUE(nchar(textToTest)<minChar)
  }


  err <- ifelse(itemExists,"taken",character(0))
  err <- c(err,ifelse(itemTooShort,sprintf("too short. Min %s letters",minChar),character(0)))
  err <- na.omit(err)

  if(!displayNameInValidation){
     textToTest = ""
  }

  if(length(err)>0){
    outTxt = (sprintf("<b style=\"color:#FF0000\">(%1$s)</b> %2$s",err,textToTest))
    isValid = FALSE
  }else{
    outTxt = (sprintf("<b style=\"color:#00CC00\">(ok)</b> %s",textToTest))
    isValid = TRUE
  }

  mxUpdateText(id=idTextValidation,text=HTML(outTxt))

  return(isValid)

}

#
# story map functions
#




#' Parse vimeo string 
#' @param text Story map text with @vimeo( id ; desc ) tag
#' @return html enabled version
#' @export
mxParseVimeo <- function(text){

  # remplacement string
  html <- tags$div(
  tags$iframe(
    src=sprintf("https://player.vimeo.com/video/%1$s?autoplay=0&color=ff0179",'\\1'),
    width="300",
    frameborder="0",
    webkitallowfullscreen="",
    mozallowfullscreen="",
    allowfullscreen=""
    ),
  span(style="font-size=10px",'\\2')
  )

  # regular expression
  expr <- "@vimeo\\(\\s*([ 0-9]+?)\\s+[;]+\\s*([ a-zA-Z0-9,._-]*?)\\s*\\)"

  # substitute
  gsub(
    expr,
    html,
    text
    )

}

#' Parse view string
#' @param test Story map text with @view_start( name ; id ; extent ) ... @view_end tags
#' @return parsed html 
#' @export
mxParseView <- function(text){

  html <- tags$div(
    class="mx-story-section mx-story-dimmed",
    `mx-map-title`="\\1",
    `mx-map-id`="\\2",
    `mx-map-extent`="[\\3]",
    "\\4"
    )


 # regular expression
  expr <- "@view_start\\(\\s*([ a-zA-Z0-9,._-]*?)\\s*;+\\s*([ a-zA-Z]*?)\\s*[;]+\\s*([ 0-9,\\.\\-]+?)\\s*\\)(.*?)@view_end"

  # substitute
  gsub(
    "(lng):|(lat):|(zoom):",
    "",
    text
    ) %>%
  gsub(
    expr,
    html,
    .
    )
 

}

#' Parse story map : markdown, R, view and video
#' @param test Story map text
#' @return parsed html 
#' @export
mxParseStory <- function(txtorig,knit=T,toc=F){

  # Parse knitr with options from markdownHTMLoptions()
  txt <- knitr::knit2html(text=txtorig,quiet = TRUE, 
    options=c(ifelse(toc,"toc",""),"base64_images","highlight_code","fragment_only")
    ) %>%
    mxParseView() %>%
    mxParseVimeo() 

    return(txt)
    
}

#' Add geojson list or file to db postgis
#' @param geojsonList list containing the geojson data
#' @param geojsonPath path the geojson
#' @param dbInfo dbInfo object containgin pass,user, .... 
#' @param tableName Name of the postgis layer / table 
dbAddGeoJSON  <-  function(geojsonList=NULL,geojsonPath=NULL,dbInfo=NULL,tableName=NULL){

  gL <- geojsonList
  gP <- geojsonPath
  tN <- tableName
  d <- dbInfo

  if(!is.null(gL) && typeof(gL) == "list"){
    gP <- tempfile(fileext=".GeoJSON")
    write(jsonlite::toJSON(gL,auto_unbox=TRUE),gP)
  }

  stopifnot(file.exists(gP))

  # db set destination
  tD <- sprintf("PG:dbname='%s' host='%s' port='%s' user='%s' password='%s'",
    d$dbname,d$host,d$port,d$user,d$password
    )
  cmd = sprintf(
    "ogr2ogr
    -t_srs 'EPSG:4326'
    -s_srs 'EPSG:4326'
    -geomfield geom
    -lco FID=gid
    -lco GEOMETRY_NAME=geom
    -lco SCHEMA=public
    -f 'PostgreSQL'
    -overwrite
    -nln '%1$s'
    '%2$s'
    '%3$s'
    OGRGeoJSON
    ",tN,tD,gP)
    cmd <- gsub("\\n","",cmd)



    # er : output. 
    er <- system(cmd,intern=TRUE)


}




#' function to read json and save as an object

mxSendJson <- function(pathToJson,objName,session=getDefaultReactiveDomain()){
  stopifnot(!is.null(pathToJson))
  stopifnot(!is.null(objName))
  if(file.exists(pathToJson)){
    res <- list()
    json <- readChar(pathToJson, file.info(pathToJson)$size)
    res$json <- json
    res$name <- objName
    session$sendCustomMessage(
      type="jsonToObj",
      message=res
      )
  }
}


