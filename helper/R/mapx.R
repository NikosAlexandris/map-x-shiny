#' Map-x helper functions
#'
#' All the R fonctions defined in map-x-shiny are container in this package
#'
#'
#' @docType package
#' @name mapxhelper 
NULL

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
  createGraph = "var myRadarChart = new Chart(ctx).Radar(data)"
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
    var chartLegend = myRadarChart.generateLegend();
    $('#'+'%s').html(function(){
      return chartLegend;
      });
    ",labels,datasetComp,datasetMain,ctx,createGraph,idLegend)
    session$sendCustomMessage(
      type="jsCode",
      list(code=js)
      )
}

#' Set map panel mode.
#'
#' Map-x panel use multiple panel mode : config,creator,explorer,toolbox. This function set and save the panel mode.
#'
#' @param session Shiny session
#' @param mode Map panel mode. In mapViewCreator, mapStoryCreator, mapExplorer
#' @param title Optionnal title to be returned.
#' @return title string
#' @export
mxSetMapPanelMode <- function(session=shiny::getDefaultReactiveDomain(),mode=c("mapViewsConfig","mapViewsCreator","mapStoryCreator","mapViewsExplorer","mapViewsToolbox"),title=NULL){
  mode = match.arg(mode)
  mxDebugMsg(paste("Set mode to : ", mode))
  jsCode <- sprintf("mxPanelMode.mode ='%s';",mode)
  session$sendCustomMessage(type="jsCode",list(code=jsCode))
  return(list(title=title,mode=mode))
}


#' Print debug message
#'
#' Print a defaut debug message with date as prefix. NOTE: this function should take a global parameter "debug" and a log file.
#'
#' @param m Message to be printed
#' @return NULL
#' @export
mxDebugMsg <- function(m=""){ 
  options(digits.secs=6)
  cat(paste0("[",Sys.time(),"]",m,'\n'))
}


#
#
#
#mxTogglePanel <- function(session=shiny::getDefaultReactiveDomain(),id){
#  jsToggle <- paste0("$('#",paste(id,"content",sep="_"),"').toggle();")
#  session$sendCustomMessage(
#    type="jsCode",
#    list(code=jsToggle)
#    )
#}
#


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
mxPanel<- function(id="default",title=NULL,subtitle=NULL,html=NULL,listActionButton=NULL,background=TRUE,defaultButtonText="OK",style=NULL,class=NULL,hideCloseButton=FALSE,draggable=TRUE){ 

  classModal = "panel-modal"
  idBack = paste(id,"background",sep="_")
  idContent = paste(id,"content",sep="_")
  jsHide <- paste0("$('#",idContent,"').toggle();$('#",idBack,"').toggle()")
  # If NULL Set default button action to "close" panel, with custom text
  if(is.null(listActionButton))listActionButton=list(
    tags$button(onclick=jsHide,defaultButtonText,class="btn btn-default")
    )
  # if explicit FALSE is given, remove modal button. 
  if(isTRUE(is.logical(listActionButton) && !isTRUE(listActionButton)))listActionButton=NULL
# close button handling
  if(hideCloseButton){
    closeButton=NULL
  }else{
    closeButton=a(href="#", onclick=jsHide,style="float:right;color:black",icon('times'))
  }

  tagList( 
    if(background){
      div(id=idBack,class=paste("panel-modal-background"))
    },

    absolutePanel(draggable=draggable,
      id=idContent,
      class=paste(class,classModal,"panel-modal-content"),
      style=style,
      closeButton,
      div(class=paste(classModal,'panel-modal-head'),  
        div(class=paste(classModal,'panel-modal-title'),title)
        ),
      div(class=paste(classModal,'panel-modal-subtitle'),subtitle),
      hr(),
      div(class=paste(classModal,'panel-modal-text'),html),
      hr(),
      div(class=paste(classModal,'panel-modal-buttons'),
        listActionButton
        )
      )
    )
}

#' Update existing panel
#'
#' Use output object to output the panel in a known id. E.g. for updating uiOutput("panelTest"), use mxUpdatePanel with panelId "panelTest"
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
mxPanelAlert <- function(title=c("error","warning","message"),subtitle=NULL,message=NULL,listActionButton=NULL){ 
  title = match.arg(title)
  switch(title,
    'error'={title=h2(icon("exclamation-circle"),toupper(title))},
    'warning'={title=h2(icon("exclamation-triangle"),toupper(title))},
    'message'={title=h2(icon("info-circle"),toupper(title))} 
    )
  mxPanel(class="panel-overall",title=title,subtitle=subtitle,html=message,listActionButton=listActionButton)
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
mxCatch <- function(title,expression,session=shiny:::getDefaultReactiveDomain(),debug=TRUE,panelId="panelAlert"){
  tryCatch({
    eval(expression)
  },error = function(e){
    session$output[[panelId]]<-renderUI({
      mxPanelAlert("error",title,message=tagList(p(e$message),p(style="",paste("(",paste(e$call,collapse=" "),")"))))
    })
  },warning = function(w){
    session$output[[panelId]]<-renderUI({
      mxPanelAlert("warning",title,message=tagList(p(w$message),p(style="",paste("(",paste(w$call,collapse=" "),")"))))
    })
  },message = function(m){
    if(debug){
      session$output[[panelId]]<-renderUI({
        mxPanelAlert("warning",title,message=tagList(p(m$message),p(style="",paste("(",paste(m$call,collapse=" "),")"))))
      })
    }
  })   
}



#' Set opacity.
#'
#' Set given layer opacity.
#' 
#' @param session Shiny session
#' @param layer Leaflet.MapboxVectorTile layer group object name
#' @param group Group
#' @param opacity Opacits
#' @export
setLayerOpacity <- function(session=shiny:::getDefaultReactiveDomain(),layer="leafletvtId",group=NULL,opacity=1){
  if(!noDataCheck(group)){
    jsCode = sprintf("if(typeof %s !== 'undefined'){%s.%s.setOpacity(%s)};",layer,layer,group,opacity)
    mxDebugMsg(jsCode)
    session$sendCustomMessage(
      type="jsCode",
      list(code=jsCode)
      )
  }
}


#' Set zIndex.
#' 
#' Set zIndex on a leafletvt layer. NOTE: leaflet seems to reset this after layer changes.
#'
#' @param session Shiny session
#' @param layer Leaflet.MapboxVectorTile layer group object name
#' @param zIndex zIndex of the group
#' @export
setLayerZIndex <- function(session=getDefaultReactiveDomain(),layer="leafletvtId",group=NULL,zIndex=15){
  if(!is.null(group)){
    jsCode <- sprintf("if(typeof %s !== 'undefined'){%s.%s.setZIndex(%s)};",layer,layer,group,zIndex)
  }else{ 
    jsCode <- sprintf("for(key in %s){%s[key].setZIndex(%s)};",layer,layer,zIndex)
  }
  if(!noDataCheck(group)){
    session$sendCustomMessage(
      type="jsCode",
      list(code=jsCode)
      )
  }
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
    tags$label(label),
    tags$input(id = inputId,class="mxLoginInput",type="password", value="")
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
    tags$label(label),
    tags$input(id = inputId, class="mxLoginInput usernameInput", value="")
    )
}



#' Toggle html element by class.
#'
#' Toggle html hide parameter by class.
#' 
#' @param session Shiny session
#' @param class CSS class to hide
#' @export 
toggleClass <- function(session=shiny:::getDefaultReactiveDomain(),class=''){
  if(!is.null(session)){
    session$sendCustomMessage(
      type="jsCode",
      list(code=sprintf("$('.test').hide()"))
      )
  }
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
  d <- dbInfo
  tryCatch({
    drv <- dbDriver("PostgreSQL")
    con <- dbConnect(drv, dbname=d$dbname, host=d$host, port=d$port,user=d$user, password=d$password)
    if(table %in% dbListTables(con)){
      ext<- dbGetQuery(con,sprintf("SELECT ST_asText(ST_centroid(ST_union(%s))) FROM %s WHERE ST_isValid(%s) = true;",geomColumn,table,geomColumn))[[1]] %>%
      strsplit(split=" ")%>%
      unlist()%>%
      gsub("[a-z,A-Z]|\\(|\\)","",.)%>%
      strsplit(split="\\s")%>%
      unlist()%>%
      as.numeric()%>%
      as.list()
      names(ext)<-c("lng","lat")
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
  d <- dbInfo
  tryCatch({
    drv <- dbDriver("PostgreSQL")
    con <- dbConnect(drv, dbname=d$dbname, host=d$host, port=d$port,user=d$user, password=d$password)
    if(table %in% dbListTables(con)){
      value <- gsub("'","''",value)
      q = sprintf("
      SELECT ST_Extent(%1$s) 
      FROM (SELECT %1$s FROM %2$s WHERE %3$s %5$s (E\'%4$s\') ) as tableFilter 
      WHERE ST_isValid(%1$s)",geomColumn,table,column,value,operator)
      ext <- dbGetQuery(con,q)[[1]]
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
  },finally={
    dbDisconnect(con)
  })
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
    div(style=style,class="panel panel-default",`data-display-if`=x$condition,
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
  tryCatch({
    d <- dbInfo
    drv <- dbDriver("PostgreSQL") 
    con <- dbConnect(drv, dbname=d$dbname, host=d$host, port=d$port,user=d$user, password=d$password)
    country = paste0("'",country,"'",collapse=",")
    if(isTRUE(table %in% dbListTables(con))){
      sql <- sprintf("SELECT * FROM %s WHERE validated is %s AND archived is %s AND country IN (%s)",table,validated,archived,country)
      res <- dbGetQuery(con,sql)
      dbDisconnect(con) 
      return(res)
    }else{
      mxDebugMsg(paste("mxGetViewsList: table",table," content requested, but not found in db."))
    }
  },finally=if(exists('con'))dbDisconnect(con)) 
}


#' Custom file input 
#'
#' Default shiny fileInput has no option for customisation. This function allows to fully customize file input using the label tag.
#'
#' @param inputId id of the file input
#' @param label Label for the input
#' @param fileAccept List of accepted file type. Could be extension.
#' @param multiple  Boolean. Allow multiple file to be choosen. Doesn't work on all browser.
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
  # set Jquery
  addDefault<-paste0("$('#",id,"').addClass('btn-default').removeClass('btn-danger').attr('disabled',false);")
  addDanger<-paste0("$('#",id,"').addClass('btn-danger').removeClass('btn-default').attr('disabled',true);")
  # toggle based on disable parameter
  val<-ifelse(disable,addDanger,addDefault)
  # send js code
  session$sendCustomMessage(
    type="jsCode",
    list(code=val)
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
  if(sty$scaleType=="continuous") { 
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
  return(sty)

}

#' Apply map-x style to existing vector tiles
#'
#' When leafletvt handle a vector tile source, a lealflet object is stored in leafletvtId, but no style is applied. Default is transparent. We add a style function after that the layer is fully loaded using this function. The style function is also stored alongside the leaflet object in leafletId under the name "vtStyle".
#'
#' @param session Shiny session object
#' @param style map-x style
#' @export 
mxSetStyle<-function(session=shiny:::getDefaultReactiveDomain(),style){
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
  
  # handle min and max date if exists.
  if(is.null(mnd))mnd=as.POSIXlt(mxConfig$minDate)
  if(is.null(mxd))mxd=as.POSIXlt(mxConfig$maxDate)

  # debug messages
  mxDebugMsg("Begin style")
  start = Sys.time()
  
  # set id of legends based on style group id.
  legendId = sprintf("%s_legends",grp)
  proxyMap <- leafletProxy("mapxMap")
  
  # If no title, take the layer name.
  if(noDataCheck(tit))tit=lay

  if(!leg){
    mxDebugMsg(sprintf("Add legend in layer id %s", legendId))
    proxyMap %>%
    addLegend(position="topright",pal=pal,values=val,title=tit,layerId = legendId)
  }else{
    mxDebugMsg(sprintf("Remove legend layer id %s", legendId))
    proxyMap %>%
    removeControl(legendId)
  }
  names(col) <- val
  sList = jsonlite::toJSON(list(
    colorsPalette = as.list(col),
    dataColum = var,
    opacity = opa,
    size = sze,
    mxDateMin = as.numeric(as.POSIXlt(mnd)),
    mxDateMax = as.numeric(as.POSIXlt(mxd))
    ))

  # send js
  jsTmpStyle <-sprintf("leafletvtSty=%s;",sList)
  jsUpdate <- sprintf("leafletvtId.%s.setStyle(updateStyle,'%s');",grp,paste0(lay,"_geom"))
  jsSaveStyle <-sprintf("leafletvtId.%s.vtStyle = leafletvtSty;",grp)


  jsCode <- paste(
    jsTmpStyle,
    jsUpdate,
    jsSaveStyle,
    collapse=""
    )

  session$sendCustomMessage(type="jsCode",list(code=jsCode))
 
  # print timing
  stop <- Sys.time() - start
  mxDebugMsg(paste("End style. Timing=",stop))
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
#' Display or hide element by id, without removing element AND without having element's space empty in UI. This function add or remove mxHide class to the element.
#'
#' @param session Shiny session
#' @param id Id of element to enable/disable 
#' @param enable Boolean. Enable or not.
#' @export
mxUiEnable<-function(session=shiny:::getDefaultReactiveDomain(),id=NULL,enable=TRUE){
  if(!enable){
    js <- sprintf("$('#%s').addClass('mxHide')",id)
  }else{
    js <- sprintf("$('#%s').removeClass('mxHide')",id)
  }
    session$sendCustomMessage(
      type="jsCode",
      list(code=js)
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

#' Set a checkbox button with custom icon.
#' 
#' Create a checkbox input with a select icon.
#'
#' @param id Id of the element
#' @param icon Name of the fontawesome icon. E.g. cog, times, wrench
#' @export
mxCheckboxIcon <- function(id,icon){
  tagList(
    div(class="checkbox",style="display:inline-block",
      tags$label(
        tags$input(type="checkbox",class="vis-hidden",id=id),
        tags$span(icon(icon))
        )
      )
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
      tags$input(type="text",id=sprintf("slider-opacity-for-%s",id)),
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
#' @export 
mxTimeSlider <-function(id,min,max){
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
              setRange('%3$s',data.from/1000,data.to/1000)
            }
          });",
          min,
          max,
          id
          )
        )
      )
    ) 
}

   

#' Update text by id
#'
#' Search for given id and update content. 
#' 
#' @param session Shiny session
#' @param id Id of the element
#' @param text New text
#' @export
mxUpdateText<-function(session=shiny:::getDefaultReactiveDomain(),id,text){
  if(is.null(text) || text==""){
    return(NULL)
  }else{
    val<-paste0("$('#",id,"').html(\"",gsub("\"","\'",text),"\");")
    session$sendCustomMessage(
      type="jsCode",
      list(code=val)
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
mxDbGetQuery <- function(dbInfo,query){
  tryCatch({
    d <- dbInfo
    drv <- dbDriver("PostgreSQL")
    con <- dbConnect(drv, dbname=d$dbname, host=d$host, port=d$port,user=d$user, password=d$password)
    res <- dbGetQuery(con,query)
    return(res)
  },finally=if(exists('con'))dbDisconnect(con)
  )
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
    return(res)
  },finally=if(exists('con'))dbDisconnect(con)
  )
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

  cmd=character(0)
  if(deleteAll){
    cmd = "clearListCookies()"
  }else{
    stopifnot(!is.null(cookie) | is.list(cookie))
    if(is.numeric(nDaysExpires) ){
      exp <- as.numeric(as.POSIXlt(Sys.time()+nDaysExpires*3600*24,tz="gmt"))
      cmd <- sprintf("document.cookie='expires='+(new Date(%s*1000)).toUTCString();",exp)
    }

    for(i in 1:length(cookie)){
      val <- cookie[i]
      if(names(val)=="d")stop('mxSetCookie:d is a reserved name')
      if(!is.na(val) && !is.null(val)){
        str <- sprintf("document.cookie='%s=%s';",names(val),val)
        cmd <- paste0(cmd,str,collapse="")
      }
    }
    }
  if(length(cmd)>0){

    #Add date
    addDate <- ";if(document.cookie.indexOf('d=')==-1){document.cookie='d='+new Date();}"
    cmd <- paste(cmd,addDate)

    session$sendCustomMessage(
      type="mxSetCookie",
      list(code=cmd)
      )
  }
}



##' Hide layer
##' @param session Shiny session
##' @param layer Leaflet.MapboxVectorTile layer group object name
##' @export
#setLayerVisibility <- function(session=shiny:::getDefaultReactiveDomain(),views="leafletvtId",status="leafletvtVisible",group=NULL,visible=TRUE){
#   if(!noDataCheck(group)){
#     val = ifelse(visible,1,0)
#     cond = ifelse(visible,'true','false')
#    setOpac = sprintf("if(typeof %s !== 'undefined'){%s.%s.setOpacity(%s)};",views,views,group,val)
#    setVisible = sprintf("if(typeof %s !== 'undefined'){%s.%s = %s };",status,status,group,cond)
#    feedback = " Shiny.onInputChange('leafletvtVisible',leafletvtVisible);"
#
#    jsCode = paste(setOpac,setVisible,feedback)
#
#    session$sendCustomMessage(
#      type="jsCode",
#      list(code=jsCode)
#      )
#  }
#
#}
#
#
#
#
###' 
##' @export
#removeModal <- function(){
#  removeClass(class="panel-modal")
#}
#' Test for 
#
#dbTestConnection <- function(dbInfo=NULL){
#  if(is.null(dbInfo)) stop('Missing arguments')
#  testOut = FALSE
#  d <- dbInfo
#
#  tryCatch({
#    drv <- dbDriver("PostgreSQL")
#    con <- dbConnect(drv, dbname=d$dbname, host=d$host, port=d$port,user=d$user, password=d$password)
#    con <- dbConnect(drv)
#
#  })
#
#}
#

#
    # Language selector by id
    #

##' Set language 
##' @param 
#l <- function(id=NULL){
#  mxConfig$languageTooltip[[id]][[mxConfig$languageChoice]]
#}

#
#  tooltip configuration
#

# update text by id


