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



#' Catch errors
#'
#' Catch errors and return alert panel in an existing div id.
#'
#' @param title Title of the alert
#' @param session Shiny session object
#' @param debug Boolean. Return also message as alert.
#' @param panelId Id of the output element
#' @export
mxCatch <- function(
  title,
  expression,
  session=shiny:::getDefaultReactiveDomain(),
  debug=TRUE,
  logToJs=TRUE,
  panelId="panelAlert",...){
  tryCatch({
    expression
  },error = function(e){
    emsg <- as.character(e$message)
    ecall <- as.character(e$call)
    if(logToJs){
      call = head(tail(sys.calls(),11),1)[[1]]
      call = as.character(call)
      mxDebugToJs(list(type="error",msg=emsg,call=ecall,context=call))
    }else{
      session$output[[panelId]]<-renderUI({
        mxPanelAlert(
          "error",
          title,
          message=tagList(
            p(emsg),
            p(style="", paste("(",paste(ecall,collapse=" "),")"))
            ),
          ...
          )
      })
    }
  },warning = function(e){
    emsg <- as.character(e$message)
    ecall <- as.character(e$call)
  if(logToJs){
      mxDebugToJs(list(type="warning",msg=emsg,call=ecall))
    }else{
    session$output[[panelId]]<-renderUI({
      mxPanelAlert(
        "warning",
        title,
        message=tagList(
          p(emsg),
          p(style="",paste("(",paste(ecall,collapse=" "),")"))
          ),
        ...
        )
    })
  }
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


#' Toggle disabling of given button, based on its id.
#'
#' Action or other button can be disabled using the attribute "disabled". This function can update a button state using this method.
#'
#' @param id Id of the button. 
#' @param session Shiny session object.
#' @param disable State of the button
#' @export
mxActionButtonState <- function(id,disable=FALSE,warning=FALSE,session=shiny:::getDefaultReactiveDomain()) {
  res <- list(
    id = id,
    disable = disable,
    warning = warning
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
  bnd <- style$bounds
  mxd <- style$mxDateMax
  mnd <- style$mxDateMin
  unt <- style$variableUnit
 





  if(noDataCheck(tit)) return()
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
  
 # if(isTRUE(!leg)){
    
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
  #}

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

  elements <- paste(paste0(prefix,element),collapse=",")


  res = list(
    enable = enable,
    element = elements,
    classToRemove = classToRemove
    )
  session$sendCustomMessage(
    type = "mxUiEnable",
    res
    )

}

#' remove element by class or id
#' @param session default shiny session
#' @param class class name to remove
#' @param id id to remove
#' @export
mxRemoveEl <- function(session=getDefaultReactiveDomain(),class=NULL,id=NULL){

  if(is.null(class) && is.null(id)) return()

sel <- ifelse(
  is.null(class),
  paste0('#',id),
  paste0('.',class)
  )

res <- list(
  element = sel
  )

session$sendCustomMessage(
  type="mxRemoveEl",
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







#' encode in base64
#' @param text character string to encode
#' @export
mxEncode <- function(text){
  base64enc::base64encode(charToRaw(as.character(text)))
}
#' decode base64 string
#' @param base64text base64string encoded 
#' @export
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
mxUpdateText<-function(id,text=NULL,ui=NULL,addId=FALSE,session=shiny:::getDefaultReactiveDomain()){
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
mxUpdateValue <- function(id,value,session=shiny:::getDefaultReactiveDomain()){
  if(is.null(value) || is.null(id)){
    return()
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

#' Parse key value pair from text
#' @param txt unformated text with key value pair. eg. myKey = myValue
#' @return list of value
#' @export
mxParseListFromText <- function(txt){
  txt2 = txt %>%
  strsplit(.,"(\n\\s*)",perl=T) %>%
  unlist(.) %>%
  gsub("^\\s*([a-z]+?)\\s*=\\s+(.+?)$","\\1 = \"\\2\"",.) %>%
  paste(.,collapse=",")%>%
  paste("list(",.,")")%>%
  parse(text=.)%>%
  eval(.)
  return(txt2)
}



#' Get layer meta stored in default layer table
#' @param dbInfo Named list with dbName,host,port,user and password
#' @param layer Postgis layer stored in layer table. Should have a meta field.
#' @export
mxGetLayerMeta <- function(dbInfo,layer){

  if(is.null(layer) || is.null(dbInfo)) return()
  layerTable <- mxConfig$layersTableName

  if(!mxDbExistsTable(dbInfo,layerTable)){
    mxDebugMsg("mxGetMeta requested, but no layer table available")
    return()
  }
  if(!mxDbExistsTable(dbInfo,layer)){
    mxDebugMsg("mxGetMeta requested, but no layer available")
    return()
  }
  # query
  query <- sprintf(
    "SELECT meta FROM %1$s WHERE \"layer\"='%2$s' AND \"validated\"='t' AND \"archived\"='f'",
    layerTable,
    layer
    )

  res <- mxDbGetQuery(dbInfo,query)$meta

  res <- jsonlite::fromJSON(mxDecode(res))

  return(res)
}

#' Get view data as list
#' @param dbInfo Named list with dbName,host,port,user and password
#' @param viewId Vector of view id(s) for which to retrieve data
#' @param select Vector of columns to retrieve
#' @export
mxGetViewData <- function(dbInfo,viewId,select=NULL){

  if(is.null(viewId) || is.null(dbInfo)) return()
  dat = list()
  # test if style is requested
  hasStyle <- "style" %in% select || is.null(select)

  viewTable <- mxConfig$viewsListTableName
 
 if(!mxDbExistsTable(dbInfo,viewTable)){
    mxDebugMsg("mxGetViewMeta requested, but no view table available")
    return()
  }

 query <- sprintf(
    "SELECT %1$s FROM %2$s WHERE \"id\" in (%3$s)",
    ifelse(is.null(select),"*",paste0(select,collapse=",")),
    viewTable,
    paste0("'",viewId,"'",collapse=",")
    )

 res <- mxDbGetQuery(dbInfo,query)

 if(isTRUE(nrow(res)>0)){
   for( i in 1:nrow(res) ){
     dat[[i]] <- as.list(res[i,]) ## as.list on single column data.frame : names are removed
     names(dat[[i]]) <- select
     if(hasStyle){
       dat[[i]]$style <- jsonlite::fromJSON(mxDecode(dat[[i]]$style))
     }
   }   
 }
  return(dat)
}



#' Remove old results from db query
#' @param dbInfo Named list with dbName,host,port,user and password
#' @export
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

#' Check if table exists in postgresql
#'
#' Shortcut to create a connection, and check if table exists. 
#'
#' @param dbInfo Named list with dbName,host,port,user and password
#' @param table Name of the table to check
#' @export
mxDbExistsTable<- function(dbInfo,table){
  tryCatch({
    d <- dbInfo
    drv <- dbDriver("PostgreSQL")
    con <- dbConnect(drv, dbname=d$dbname, host=d$host, port=d$port,user=d$user, password=d$password)
    res <- dbExistsTable(con,table)
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
    tAppend <- FALSE
    if(tExists){
      tNam <- names(table)
      rNam <- dbListFields(con,table)
      if(!all(tNam %in% rNam)){
        wText <- sprintf("mxDbAddData: remote table %1$s has fields: '%2$s', table to append: '%3$s'",
          table,
          paste(rNam,collapse="; "),
          paste(tNam,collapse="; ")
          )
        stop(wText)
      }else{
        tAppend = TRUE
      }
    }

    dbWriteTable(con,name=table,value=data,append=tAppend,row.names=F)

    dbDisconnect(con)
  },finally=if(exists('con'))dbDisconnect(con)
  )
}


mxDbUpdate <- function(dbInfo,table,column,idCol="id",id,value){
    
   query <- sprintf("
      UPDATE %1$s
      SET \"%2$s\"='%3$s'
      WHERE \"%4$s\"='%5$s'",
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

#' extract views from the db and create a list
#' @param dbInfo map-x db info list
#' @param cntry Country iso3 code
#' @return list of views data and style 
#' @export
 mxMakeViewList <- function(dbInfo,cntry){
      views = list()
      if(!noDataCheck(cntry)){
        viewsDf <- mxGetViewsTable(dbInfo,mxConfig$viewsListTableName,country=cntry)
        if(isTRUE(nrow(viewsDf)>0)){
          # create list of map views
          for(i in viewsDf$id){
            views[[i]] <- as.list(viewsDf[viewsDf$id==i,])
            views[[i]]$style <- fromJSON(mxDecode(views[[i]]$style))
          }
        }
      }
      return(views)
    }


#' Save named list of value into cookie
#'
#' Note : don't use this for storing sensitive data, unless you have a trusted network.
#'
#' @param session Shiny session object. By default: default reactive domain.
#' @param cookie Named list holding paired cookie value. e.g. (list(whoAteTheCat="Alf"))
#' @param nDaysExpires Integer of days for the cookie expiration
#' @param read Boolean. Read written cookie
#' @return NULL
#' @export
mxSetCookie <- function(
  session=getDefaultReactiveDomain(),
  cookie=NULL,
  nDaysExpires=NULL,
  deleteAll=FALSE,
  read=TRUE
  ){

  cmd = list()
  cmd$domain <- session$url_hostname
  cmd$path <- session$url_pathname
  cmd$deleteAll <- deleteAll
  cmd$cookie <- cookie
  cmd$expiresInSec <- nDaysExpires * 86400
  cmd$read <- read
 
  session$sendCustomMessage(
    type="mxSetCookie",
    cmd
    )
}

#' Get cookie from session HTTP request

mxGetCookies <- function(
  session=getDefaultReactiveDomain()  
  ){
  val = list()
  ck <- unlist(strsplit(session$request$HTTP_COOKIE,"; "))
  if(!noDataCheck(ck)){
    ck <- read.table(text=ck,sep="=",stringsAsFactor=FALSE)
    val <- as.list(ck$V2)
    names(val) <- ck$V1
  }

  return(val)
}







#' Overlaps analysis 
#' 
#' Use a mask to get overlaps over a layer
#' @export
mxAnalysisOverlaps <- function(dbInfo,inputBaseLayer,inputMaskLayer,outName,dataOwner="mapxw",sridOut=4326,varToKeep="gid"){

  msg=character(0)
  if(!outName %in% mxDbListTable(dbInfo)){

    #varToKeep <- paste0(sprintf("%s.%s",inputBaseLayer,varToKeep),collapse=",")
    #createTable <- sprintf("
      #CREATE TABLE %1$s AS SELECT %4$s, 
      #ST_Multi(ST_Buffer(ST_Intersection(%3$s.geom, %2$s.geom),0.0))
      #FROM %3$s
      #INNER JOIN %2$s
      #ON ST_Intersects(%3$s.geom, %2$s.geom)
      #WHERE Not ST_IsEmpty(ST_Buffer(ST_Intersection(%3$s.geom, %2$s.geom),0.0));
      #ALTER TABLE %1$s
      #ALTER COLUMN geom TYPE geometry(MultiPolygon, %5$i) 
      #USING ST_SetSRID(geom,%5$i);
      #ALTER TABLE %1$s OWNER TO %6$s;
      #ALTER TABLE %1$s ADD COLUMN gid BIGSERIAL PRIMARY KEY;
      #",
      #outName,
      #inputBaseLayer,
      #inputMaskLayer,
      #varToKeep,
      #sridOut,
      #dataOwner
      #)

    # get geometry type. 
    # NOTE: qgis seems confused if the geom type is not updated.
    geomType <- mxDbGetQuery(
      dbInfo,
      sprintf("select GeometryType(geom) FROM %s limit 1",
        inputBaseLayer
        )
      )[[1]]
    varBase <- paste0(sprintf("a.%s",varToKeep[!varToKeep %in% "geom"]),collapse=",")
    createTable <- gsub("\n|\\s+"," ", sprintf("
        CREATE TABLE %1$s AS
        SELECT
        %2$s,
        b.gid AS mask_gid,
        CASE 
        WHEN ST_Within(a.geom,b.geom) 
        THEN a.geom
        ELSE ST_Multi(ST_Intersection(a.geom,b.geom)) 
        END AS geom
        FROM %3$s a
        JOIN %4$s b
        ON ST_Intersects(a.geom, b.geom);
        ALTER TABLE %1$s
        ALTER COLUMN geom TYPE geometry(%7$s, %5$i) 
        USING ST_SetSRID(geom,%5$i);
        ALTER TABLE %1$s OWNER TO %6$s;
        DO
        $$
        BEGIN
        IF not EXISTS (
          SELECT attname 
          FROM pg_attribute 
          WHERE attrelid = (
            SELECT oid 
            FROM pg_class 
            WHERE relname = '%1$s'
            ) AND attname = 'gid') THEN
        ALTER TABLE %1$s ADD COLUMN gid BIGSERIAL PRIMARY KEY;
      ELSE
        raise NOTICE 'gid already exists';
  END IF;
  END
  $$
  "
  ,outName
  ,varBase
  ,inputBaseLayer
  ,inputMaskLayer
  ,sridOut
  ,dataOwner
  ,geomType
  )
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
   mxStyleReset <-function(reactiveObj){

     sty <- mxConfig$defaultStyle
     styName <- names(sty)
    #rList <- names(reactiveValuesToList(reactiveObj))
     for(n in styName){
     reactiveObj[[n]]<-sty[[n]]
     }
    }

#' Set zoom button options
#' @param map Leaflet map object
#' @param butonOptions List of  Leaflet options for zoom butons. E.g. list(position="topright") 
#' @param removeButton Boolean. Remove the zoom button.
#' @export
setZoomOptions <- function(map,buttonOptions=list(),removeButton=FALSE){ 
  invokeMethod(map,NULL,'setZoomOptions',buttonOptions,removeButton)
}



#' String validation
#' 
#' Check if a string exists in a vector of string, if there is a duplicate, if contains at least n character, etc.. and update an existing div with a html summary. Return if the string is valid or not.
#' 
#' @param textTotest text to test against rules
#' @param existingTexts  Vector of existing text
#' @param idTextValidation Id of the ui element to update (id=example -> uiOutput("example"))
#' @param minChar Minimum character length
#' @param testForDuplicate Boolean test for duplicate.
#' @param testForMinChar Boolean test for minimum number of character
#' @param displayNameInValidation Boolean add text in validation text
#' @return boolean : valid or not
#' @export
mxTextValidation <- function(textToTest,existingTexts,idTextValidation,minChar=5,testForDuplicate=TRUE,testForMinChar=TRUE,displayNameInValidation=TRUE,existsText="taken",errorColor="#FF0000"){

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


  err <- ifelse(itemExists,existsText,character(0))
  err <- c(err,ifelse(itemTooShort,sprintf("too short. Min %s letters",minChar),character(0)))
  err <- na.omit(err)

  if(!displayNameInValidation){
     textToTest = ""
  }

  if(length(err)>0){
    outTxt = (sprintf("<b style=\"color:%1$s\">(%2$s)</b> %3$s",errorColor,err,textToTest))
    isValid = FALSE
  }else{
    outTxt = (sprintf("<b style=\"color:#00CC00\">(ok)</b> %s",textToTest))
    isValid = TRUE
  }

  mxUpdateText(id=idTextValidation,text=HTML(outTxt))

  return(isValid)

}


#' R list to html
#' @param listInput list in inptu
#' @param htL List to append to
#' @param h Value of the first level of html header
#' @param exclude list named item to exclude
#' @export
listToHtml<-function(listInput,htL='',h=2, exclude=NULL){

  hS<-paste0('<H',h,'><u>',collapse='') #start 
  hE<-paste0('</u></H',h,'>',collapse='') #end
  h=h+1 #next
  if(is.list(listInput)){
    nL<-names(listInput)
    nL <- nL[!nL %in% exclude]
    htL<-append(htL,'<ul>')
    for(n in nL){
      htL<-append(htL,c(hS,n,hE))
      subL<-listInput[[n]]
      htL<-listToHtml(subL,htL=htL,h=h,exclude=exclude)
    }
    htL<-append(htL,'</ul>')
  }else if(is.character(listInput) || is.numeric(listInput)){
    htL<-append(htL,c('<li>',paste(listInput,collapse=','),'</li>'))
  }
  return(paste(htL,collapse=''))
}

#' R list to html list
#'
#' Create a html list and apply a class for <ul> and <li>
#'
#' @param listInput list in inptu
#' @param htL List to append to
#' @param h Value of the first level of html header
#' @param exclude list named item to exclude
#' @return HTML list 
#' @export
listToHtmlClass <- function(listInput, exclude=NULL, c=0, htL="",classUl="list-group",classLi="list-group-item"){

  c = c+1 #next

  if(is.list(listInput)){
    nL <- names(listInput)
    nL <- nL[!nL %in% exclude]
    htL <- append(
      htL,
      paste(
        '<ul class="',
        paste(
          classUl,
          collapse=","
          ),
        '">'
        )
      ) # open
    for(n in nL){
#      htL <- append(htL,c(hS,n,hE))
  htL<-append(
      htL,
      c(
        paste(
          '<li class="',
          paste(classLi,collapse=","),
          '">'
          ),
        n)
      )
      subL <- listInput[[n]]
      htL <- listToHtmlClass(
        subL, 
        exclude=exclude,
        htL=htL,
        c=c,
        classUl=classUl,
        classLi=classLi
        )
    }
    htL<-append(htL,'</li></ul>') # close

  }else if(is.character(listInput) || is.numeric(listInput)){

    htL<-append(
      htL,
      paste("<b>",listInput,"</b>")
      )

  }
  return(paste(htL,collapse=''))
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


