#' Map-x helper functions
#'
#' Map-x core functions
#'
#'
#' @docType package
#' @name mapxhelper 
NULL

##' Check for no null, NA's, nchar of 0, lenght of 0  or "[NO DATA]" string in a vector.
##' @param val  Vector to test for no data.
##' @return TRUE if no data (nchar == 0 OR is.na OR is.null) found or if input is not a vector
##' @export
#noDataCheck<-function(val,useNoData=TRUE,noDataVal="[ NO DATA ]"){
  ##if(!is.vector(val)) stop(paste("val should be a vector. Provided value=",typeof(val)))
  #if(!is.vector(val)){
    #return(TRUE)
  #}
  #if(useNoData){
    #noData <- all(noDataVal %in% val)
  #}else{
    #noData <- FALSE
  #}
  #any(c(isTRUE(is.null(val)),isTRUE(is.na(val)),isTRUE(nchar(val)==0),isTRUE(length(val)==0),noData))
#}


#' Check for "empty" value
#' 
#' Empty values = NULL or, depending of storage mode
#' - data.frame : empty is 0 row
#' - list : empty is length of 0
#' - vector (without list) : empty is length of 0 OR first value in "mxConfig$defaultNoDatas" OR first value is NA or first value as character length of 0
#'
#' @param val object to check : data.frame, list or vector (non list). 
#' @return Boolean TRUE if empty
#' @export
noDataCheck <- function( val = NULL ){
  val
  isTRUE(
    is.null(val)
    ) ||
  isTRUE(
    isTRUE( is.data.frame(val) && nrow(val) == 0 ) ||
    isTRUE( is.list(val) && ( length(val) == 0 ) ) ||
    isTRUE( !is.list(val) && is.vector(val) && ( 
        length(val) == 0 || 
          val[[1]] %in% mxConfig$defaultNoDatas || 
          is.na(val[[1]]) || 
          nchar(val[[1]]) == 0 )
      )
    )
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
mxUpdateChartRadar <- function(
  session=shiny::getDefaultReactiveDomain(),
  main,
  compMain,
  id,
  idLegend,
  labels,
  values,
  compValues
  ){
  stopifnot(is.vector(values) || is.vector(label))

  colorMain = 'rgba(119,119, 119, 0.3)'
  colorMainBorder = 'rgba(119,119, 119, 0.5)'
  colorComp = 'rgba(255, 164, 0, 0.3)'
  colorCompBorder = 'rgba(255, 164, 0, 0.5)'



  res <- list()
  res$id <- id
  res$labels <- labels
  res$idLegend <- idLegend
  res$dataMain <-  list(
    label = main,
    backgroundColor = colorMain,
    borderColor = colorMainBorder,
    pointBackgroundColor = colorMain,
    pointBorderColor = colorMainBorder,
    pointHoverBackgroundColor =colorMain,
    pointHoverBorderColor = colorMainBorder,
    data = values
    )
  res$dataComp <- list(
    label = compMain,
    backgroundColor = colorComp,
    borderColor = colorCompBorder,
    pointBackgroundColor = colorComp,
    pointBorderColor = colorCompBorder,
    pointHoverBackgroundColor =colorComp,
    pointHoverBorderColor = colorCompBorder,
    data = compValues
    )

  session$sendCustomMessage(
    type="updateChart",
    res
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
  options(digits.secs=4)
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
  logToJs=FALSE,
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
          message=tagList(p("Something went wrong, sorry!"))
          )
      })


      msgLog <- paste(
        emsg,
        paste("(",paste(ecall,collapse=" "),")")
        )



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



#' Random string generator
#' 
#' Create a random string with optional settings.
#' 
#' @param prefix Prefix. Default = NULL
#' @param suffix Suffix. Default = NULL
#' @param n Number of character to include in the random string
#' @param sep Separator for prefix or suffix
#' @param addSymbols Add random symbols
#' @param addLetters Add random letters (upper and lowercase)
#' @param splitIn Split string into chunk, with separator as defined in splitSep
#' @param splitSep Split symbos if splitIn > 1
#' @return  Random string of letters, with prefix and suffix
#' @export
randomString <- function(prefix=NULL,suffix=NULL,n=15,sep="_",addSymbols=F,addLetters=T,addLETTERS=F,splitIn=1,splitSep="_"){
  prefix <- subPunct(prefix,sep)
  suffix <- subPunct(suffix,sep)
  src <- 0:9

  if(splitIn<1) splitIn=1
  if(isTRUE(addSymbols)) src <- c(src,"$","?","=",")","(","/","&","%","*","+")
  if(isTRUE(addLetters)) src <- c(letters,src)
  if(isTRUE(addLETTERS)) src <- c(LETTERS,src)

  grp <- sort(1:n%%splitIn)

  rStr <- src %>% 
     sample(size=n,replace=T) %>%
      split(grp) %>%
      sapply(paste,collapse="") %>%
      paste(collapse=splitSep)

  c(prefix,rStr,suffix) %>%
  paste(collapse=sep)
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
  if(!is.null(cmd) && nchar(cmd)>0){
   
    if(vagrant){
      res =  system(sprintf("ssh %s -F %s -C \"%s\"",host,sshConfig,cmd),intern=TRUE)

    }else{

      res =  system(sprintf("ssh -p %s %s@%s %s",port,user,host,cmd),intern=TRUE)
    }
  }
  return(res)
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




#mxToggleMapPanels <- function(modeSelected){
  #modeAvailable <- mxConfig$mapPanelModeAvailable

  #if(!isTRUE(modeSelected %in% modeAvailable)){
    #stop(sprintf("Map panel mode % not available. Set it in mxConfig",modeSelected))
  #}

  #stopifnot(modeSelected %in% modeAvailable)
  #mS <- modeSelected
  #mA <- modeAvailable
  #mD <- mA[!mA %in% mS]
  #mxUiEnable(class=mS,enable=TRUE)
  #mxUiEnable(class=mD,enable=FALSE)
#}


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



mxEncrypt <- function(text,key){



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
#' @param layer Postgis layer stored in layer table. Should have a meta field.
#' @export
mxGetLayerMeta <- function(layer){

  if(is.null(layer)) return()
  
  layerTable <- mxConfig$layersTableName

  if(!mxDbExistsTable(layerTable)){
    mxDebugMsg("mxGetMeta requested, but no layer table available")
    return()
  }
  if(!mxDbExistsTable(layer)){
    mxDebugMsg("mxGetMeta requested, but no layer available")
    return()
  }
  # query
  query <- sprintf(
    "SELECT meta FROM %1$s WHERE \"layer\"='%2$s'",
    layerTable,
    layer
    )

  res <- mxDbGetQuery(query)$meta
  res <- res[length(res)]

  if(isTRUE(nchar(res)>0)){
    res <- jsonlite::fromJSON(res)
  }else{
    res <- list()
  }
  return(res)
}

#' Get view data as list
#' @param viewId Vector of view id(s) for which to retrieve data
#' @param select Vector of columns to retrieve
#' @export
mxGetViewData <- function(viewId,select=NULL){

  if(is.null(viewId)) return()
  dat = list()
  # test if style is requested
  hasStyle <- "style" %in% select || is.null(select)

  viewTable <- mxConfig$viewsListTableName

  if(!mxDbExistsTable(viewTable)){
    mxDebugMsg("mxGetViewMeta requested, but no view table available")
    return()
  }

  query <- sprintf(
    "SELECT %1$s FROM %2$s WHERE \"id\" in (%3$s)",
    ifelse(is.null(select),"*",paste0(select,collapse=",")),
    viewTable,
    paste0("'",viewId,"'",collapse=",")
    )

  res <- mxDbGetQuery(query)

  if(isTRUE(nrow(res)>0)){
    for( i in 1:nrow(res) ){
      dat[[i]] <- as.list(res[i,]) ## as.list on single column data.frame : names are removed
      names(dat[[i]]) <- select
      if(hasStyle){
        dat[[i]]$style <- jsonlite::fromJSON(dat[[i]]$style)
      }
    }   
  }
  return(dat)
}
#' extract views from the db and create a list
#' @param cntry Country iso3 code
#' @return list of views data and style 
#' @export
mxMakeViewList <- function(country,visibility,userId){
  views = list()
  if(!noDataCheck(country)){
    viewsDf <- mxGetViewsTable(
      table=mxConfig$viewsListTableName,
      country=country,
      userId=userId,
      visibility=visibility
      )
    if(isTRUE(nrow(viewsDf)>0)){
      # create list of map views
      for(i in viewsDf$id){
        views[[i]] <- as.list(viewsDf[viewsDf$id==i,])
        views[[i]]$style <- fromJSON(views[[i]]$style)
      }
    }
  }
  return(views)
}


#' Retrieve map views table 
#'
#' Get a list of available map-x views in given table, e.g. mx_views 
#'
#' @param table Table name containing views info
#' @param validated Boolean filter validated dataset. Default = TRUE
#' @param archived Boolean filter to get archived data. Default =FALSE
#' @param country ISO 3 code to filter country. 
#' @export
mxGetViewsTable <- function(table="mx_views",validated=TRUE,archived=FALSE,country="AFG",visibility="public",userId=""){

  classesOrig = as.character(mxConfig$class)
  country = paste0("'",country,"'",collapse=",")
  visibility = paste0("'",visibility[!visibility %in% 'self'],"'",collapse=",")
  classes = paste0("'",classesOrig,"'",collapse=",")



  orderClass = paste(
    sapply(classesOrig,
      function(x){
        rank = which(classesOrig==x) 
        sprintf("WHEN '%s' then %i",x,rank)
      }),
    collapse=" ")
 
  orderClass = paste('CASE "class"',orderClass,"ELSE 50 END",sep=" ")


  if(any(sapply(c(country,visibility,orderClass),noDataCheck))) stop("Get views from db : missing values")

  if(isTRUE(mxDbExistsTable(table))){

    q <- sprintf(
      "SELECT * FROM %s 
      WHERE archived is %s 
      AND country IN (%s)
      AND class IN (%s)
      AND ( visibility ?| array[%s] OR editor = '%s' )
      ORDER BY %s
      "
      ,table
      ,archived
      ,country
      ,classes
      ,visibility
      ,userId
      ,orderClass
      )

    res <- mxDbGetQuery(q)
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






#' Encrypt or decrypt data using postgres pg_sym_encrypt
#' 
#' 
#'
#' @param data vector, list or data.frame to encrypt or decrypt
#' @param ungroup boolean : ungroup the data and apply the encryption on individual item.
#' @param key Encryption key
#' @return encrypted data as list
#' @export
mxDbEncrypt <- function(data,ungroup=FALSE,key=mxConfig$key){

  if(ungroup){
      data <- sapply(data, mxToJsonForDb)
    }else{
      data <- mxToJsonForDb(data)
    }
    q <- sprintf(
      "(SELECT mx_encrypt('%1$s','%2$s') as res)",
      data,
      key
      )
    if(length(q)>1) q <- paste(q,collapse=" UNION ALL ")

    # Execute querry
    res <- as.list(mxDbGetQuery(q))$res

    return(res)
}
#' @rdname mxDbEncrypt
mxDbDecrypt <- function(data=NULL,key=mxConfig$key){

  out <- try({
    # if vector containing encrypted data is empty (or not a vector.. see noDataCheck) OR
    # if nchar is not even (should be hex data)
    if(
      is.null( data ) ||
      !all( sapply( data, length ) > 0) ||  
      !all( sapply( data, is.character )) ||
      !all( sapply( data, nchar )%%2 == 0)
    ) return()

    query <- sprintf("SELECT mx_decrypt('%1$s','%2$s') as res",
      data,
      key
      )
    if(length(query)>1) query <- paste(query,collapse=" UNION ALL ")

    res <- mxDbGetQuery(query)$res

    if(!is.null(res) && !is.na(res)) {
      # if we convert r object as json with mxDbEncrypt, we may want 
      # retrieve decrypt no json based text.
      isJSON <- all(sapply(res,jsonlite::validate))

      if(isJSON){
      if(length(res)>1) {
        out <- lapply(res,jsonlite::fromJSON,simplifyVector=T)
      }else{ 
        out <- jsonlite::fromJSON(res,simplifyVector=T)
      }
      }else{
       out <- res
      }
    }

  },silent=T)
  return(out)
}

#' Get group table for users
#' @param idFilter optional filter of vector containing ids
mxDbGetUsersGroups<-function(idFilter=NULL){
  filter = ""
  if(!is.null(idFilter)) filter = paste(sprintf("WHERE id=%s",idFilter),collapse="OR")
q = sprintf(
    "SELECT id, grp 
    FROM ( 
      SELECT id, jsonb_array_elements_text(data_admin->'group') as grp 
      FROM mx_users
      %1$s 
      ) t",
    filter
    )
res = mxDbGetQuery(q)
return(res)
}


#' Create random secret
#'
#' Get a random string .
#'
#' @param n Number of character
#' @export
mxCreateSecret =  function(n=20){
  randomString(20)
}


#' Check if given email is valid
#' @param email String email address to verify
#' @return named logic vector
#' @export
mxEmailIsValid <- function(email=NULL){

  res = FALSE
  if(!noDataCheck(email)){
    email <- as.character(email)
    tryCatch({
      # regex expression
      # see http://stackoverflow.com/questions/201323/using-a-regular-expression-to-validate-an-email-address
      regex <- "([-!#-'*+/-9=?A-Z^-~]+(\\.[-!#-'*+/-9=?A-Z^-~]+)*|\"([]!#-[^-~ \\t]|(\\\\[\\t -~]))+\")@[0-9A-Za-z]([0-9A-Za-z-]{0,61}[0-9A-Za-z])?(\\.[0-9A-Za-z]([0-9A-Za-z-]{0,61}[0-9A-Za-z])?)+"
      # if there is a match, return TRUE
      res <- sapply(email,function(e){
        isTRUE(grep(regex,x=e,perl=T)==1)
    })},error=function(x){
        return()
    })
  }
  return(res)
}



#' Save named list of value into cookie
#'
#' Note : don't use this for storing sensitive data, unless you have a trusted network.
#'
#' @param session Shiny session object. By default: default reactive domain.
#' @param cookie Named list holding paired cookie value. e.g. (list(whoAteTheCat="Alf"))
#' @param expireDays Integer of days for the cookie expiration
#' @param read Boolean. Read written cookie
#' @return NULL
#' @export
mxSetCookie <- function(
  cookie=NULL,
  expireDays=NULL,
  deleteAll=FALSE,
  reloadPage=FALSE,
  session=getDefaultReactiveDomain()
  ){

  cmd = list()
  cmd$domain <- session$url_hostname
  cmd$path <- session$url_pathname
  cmd$deleteAll <- deleteAll
  cmd$cookie <- cookie
  cmd$reload <- reloadPage
  cmd$expiresInSec <- expireDays * 86400

  session$sendCustomMessage(
    type="mxSetCookie",
    cmd
    )
}

##' Get cookie from session HTTP request
# shiny server can remove cookies
#mxGetCookies <- function(
  #session=getDefaultReactiveDomain()  
  #){
  #val = list()
  #ck <- unlist(strsplit(session$request$HTTP_COOKIE,"; "))
  #if(!noDataCheck(ck)){
    #ck <- read.table(text=ck,sep="=",stringsAsFactor=FALSE)
    #val <- as.list(ck$V2)
    #names(val) <- ck$V1
  #}

  #return(val)
#}







#' Overlaps analysis 
#' 
#' Use a mask to get overlaps over a layer
#' @export
mxAnalysisOverlaps <- function(inputBaseLayer,inputMaskLayer,outName,dataOwner="mapxw",sridOut=4326,varToKeep="gid"){

  msg <- character(0)

  if(!mxDbExistsTable(outName)){

    # get geometry type. 
    # NOTE: qgis seems confused if the geom type is not updated.
    geomType <- mxDbGetQuery(
      sprintf("select GeometryType(geom) as gt FROM %s limit 1",
        inputBaseLayer
        )
      )$gt

    varBase <- paste0(sprintf("a.%s",varToKeep[!varToKeep %in% "geom"]),collapse=",")

        #ALTER TABLE %1$s
        #ALTER COLUMN geom TYPE geometry(%7$s, %5$i) 
        #USING ST_SetSRID(geom,%5$i);
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
    mxDbGetQuery(createTable) 
  }
}


#' Create a formated list of available palettes
#' @export
mxCreatePaletteList <- function(){
  pals <- RColorBrewer::brewer.pal.info
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
    itemExists <- isTRUE(tolower(textToTest) %in% tolower(unlist(existingTexts)))
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
listToHtmlClass <- function(listInput, exclude=NULL,title=NULL,c=0, htL="",classUl="list-group",classLi="list-group-item"){

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

    for(i in 1:length(listInput)){
      subL <- listInput[[i]]
      htL<-append(
        htL,
        c(
          paste(
            '<li class="',
            paste(classLi,collapse=","),
            '">'
            )
          )
        )
      htL <- listToHtmlClass(
        subL, 
        exclude=exclude,
        title=nL[[i]],
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
      sprintf(
        "
        <span class='mx-list-title'>%1$s: </span>
        <span class='mx-list-content'>%2$s</span>
        "
        , title
        , listInput
        )
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



#' Send an email using local or remote 'mail' command
#' @param from String. Valid email for  sender
#' @param to String. Valid email for Recipient
#' @param body String. Text of the body
#' @param subject. String. Test for the subject 
#' @export
mxSendMail <- function(from=mxConfig$mapxBotEmail,to=NULL,body="",subject="",wait=FALSE){


  stopifnot(
    mxEmailIsValid(from),
    mxEmailIsValid(to),
    is.character(body),
    is.character(subject)
    )

  if(!all(
      c(mxEmailIsValid(from),
        mxEmailIsValid(to),
        isTRUE(is.character(body)),
        isTRUE(is.character(subject)),
        isTRUE(nchar(body)>0),
        isTRUE(nchar(subject)>0)
      )
    )) stop("mxSendMail : bad input")

  sendEmail <- sprintf("echo '%1$s' | mailx -a 'Content-Type: text/html' -s '%2$s' -a 'From: %3$s' %4$s",
    body,
    subject,
    from,
    to
    )

  if( mxConfig$hostname != mxConfig$remoteHostname ){
    r <- mxConfig$remoteInfo  
    remoteCmd(host=mxConfig$remoteHostname,cmd=sendEmail)
  }else{
    system(sendEmail,wait=wait)
  }


}

#' Check if an email is known and active
#'
#' Check in a standard mapx database if an email/user exists
#'
#' @param email map-x user email
#' @param usertable name of the table
#' @return boolean exists
#' @export
mxEmailIsKnown <- function(email=NULL,usertable="mx_users",active=TRUE,validated=TRUE){
  if(is.null(email)) return()
  email <- as.character(email)
  q <- sprintf(
    "SELECT count(\"id\")
    FROM %1$s 
    WHERE email='%2$s'
    AND validated='%3$s'
    AND hidden='%4$s' ",
    usertable,
    email,
    ifelse(validated,"true","false"),
    ifelse(!active,"true","false")
    )
  res <- mxDbGetQuery(q)
  return(isTRUE(nrow(res)>0 && res$count > 0))
}


#' Recursive search and filter on named list
#' @param li List to evaluate
#' @param column Named field to search on (unique)
#' @param operator Search operator ('>','<','==','>=','<=','!=','%in%')
#' @param search Value to search
#' @param filter Named field to keep
#' @return list or named vector if filter is given
#' @export
mxRecursiveSearch <- function(li,column="",operator="==",search="",filter=""){

  res <- NULL
  stopifnot(operator %in% c('>','<','==','>=','<=','!=','%in%'))
  expr <- paste("li[[column]]",operator,'search')
  if( is.list(li)  && length(li) > 0 ){ 
    if( column %in% names(li) &&  eval(parse(text=expr)) ){
      return(li)
    }else{     
      val <- lapply(li,function(x) mxRecursiveSearch(
          li=x,
          search=search,
          operator=operator,
          column=column,
          filter=filter
          )
        )
      val <- val[sapply(val,function(x) !is.null(x))]
      if(length(val)>0){
        if(is.null(filter) || nchar(filter)==0){
          res <- val
        }else{
          res <- unlist(val)
          res <- res[grepl(paste0(filter,collapse='|'),names(res))]
        }
        return(res)
      }
    }
  }
}

#' Extract value from a list given a path
#' @param listInput Input named list
#' @param path Path inside the list
#' @return value extracted or NULL
#' @export
mxGetListValue <- function(listInput,path){
  if(!is.list(listInput) || length(listInput) == 0) return()
  out = NULL
  res <- try(silent=T,{
    out<-listInput[[path]]
  })
  return(out)
} 

#' Set a value of a list element, given a path
#'
#' This function will update a value in a list given a path. If the path does not exist, it will be created. 
#' If the function find a non list element before reaching destination, it will stop.
#'
#' @param path vector with name of path element. e.g. `c("a","b","c")`
#' @param value value to update or create
#' @param level starting path level, default is 0
#' @param export
mxSetListValue <- function(listInput,path,value,level=0){
  level <- level+1 
  p <- path[c(0:level)]
  #
  # Create parsable expression to acces non existing list element
  #
  liEv = paste0("listInput",paste0(paste0("[[\"",p,"\"]]",sep=""),collapse=""))

  if(is.null(eval(parse(text=liEv)))){
    #
    # If the element does not exist, it's a list
    # 
    liSet = paste0(liEv,"<-list()")
    eval(parse(text=liSet))
  }
  if(level == length(path)){
    #
    # We reached destination, set value
    #
    listInput[[p]] <- value
  }else{
    #
    # If we encouter non-list value, stop, it's not expected.
    #
    if(!is.list(listInput[[p]])) stop(sprintf("Not a list at %s",paste(p,collapse=",")))
    listInput <- mxSetListValue(listInput,path,value,level)
  }
  return(listInput)
} 







#' Return the highest role for a given user
#' @param project Project to look for
#' @param userInfo object of class mxUserInfoList produced with mxDbGetUserInfoList 
#' @export
mxGetMaxRole <- function(project,userInfo){

  stopifnot(isTRUE("mxUserInfoList" %in% class(userInfo)))

  levelProject <- 10
  levelWorld <- 10

  userRoles <- mxGetListValue(userInfo,c("data","admin","roles"))


  # NOTE: Backward compatibility with previous version.
  if("world" %in% names(userRoles)) {
  userRoles <- list(userRoles,list(
    project = "world",
    role = userRoles[["world"]]
    ))
  }
  if("AFG" %in% names(userRoles) ) {
  userRoles <- list(userRoles,list(
    project = "AFG",
    role = userRoles[["AFG"]]
    ))
  }
  if("COD" %in% names(userRoles) ) {
  userRoles <-list(userRoles,list(
    project = "COD",
    role = userRoles[["COD"]]
    ))
  }


  # get role for project
  roleInProject <- mxRecursiveSearch(
    li=userRoles,"project","==",project
    )[[1]]$role
  # Get role for world

  roleInWorld <- mxRecursiveSearch(
    li=userRoles,"project","==","world"
    )[[1]]$role
  
  hasRoleInProject <- !noDataCheck(roleInProject)
  hasRoleInWorld <- !noDataCheck(roleInWorld)

  if(!hasRoleInWorld && !hasRoleInWorld) stop("No role found!")

  if(hasRoleInProject){
    levelProject <- mxRecursiveSearch(
      li=mxConfig$roles,"role","==",roleInProject
      )[[1]]$level
  }

  if(hasRoleInWorld){
    levelWorld <- mxRecursiveSearch(
      li=mxConfig$roles,"role","==",roleInWorld
      )[[1]]$level
  }

  levelUser <- min(c(levelWorld,levelProject))

  mxRecursiveSearch(mxConfig$roles,"level","==",levelUser)[[1]]
}


##' Format roles from database 
##' @param x named role list to keyed (location:role value pair)
#mxFormatRole_toKeyed <- function(x){
  #res = list()
  #for(i in names(x)){
  #res=c(res,list(
      #list(
    #project=i,
    #role=x[[i]]
    #)
    #)
    #)
  #}
  #return(res)
#}

##' Format roles from database to roles used in jed format
##' @param x keyed list to convert to named (location:role value pair)
 
##' @export
#mxFormatRole_toNamed <- function(x){
  #res <- sapply(x,`[[`,"role")
  #names(res) <- sapply(x,`[[`,"project")
  #as.list(res)
#}
## test 
## dat = list("AFG"="user","world"="public")
## identical(mxFormatRole_toNamed(mxFormatRole_toKeyed(dat)),dat)


#' Time interval evaluation
#' @param action "start" or "stop" the timer
#' @param timerTitle Title to be displayed in debug message
#' @return
mxTimer <- function(action=c("stop","start"),timerTitle="Mapx timer"){
  action <- match.arg(action)
  if(isTRUE(!is.null(action) && action=="start")){
    .mxTimer <<- list(time=Sys.time(),title=timerTitle)
  }else{
    if(exists(".mxTimer")){
      diff <- paste(round(difftime(Sys.time(),.mxTimer$time,units="secs"),3))
      mxDebugMsg(paste(.mxTimer$title,diff,"s"))
    }
  }
}

#' Get session duration for given id
#' @param id Integer id of the user
#' @return list with H,M,S since last visit
#' @export
mxGetSessionDurationHMS <-function(id=NULL){
  if(is.null(id)) return()
  res <- 
    list(
      H=0,
      M=0,
      S=0
      )

  sessionStart <- mxDbGetQuery(sprintf(
      "SELECT date_last_visit as start FROM mx_users WHERE id = %1$s"
      , id
      )
    )$start

  if(noDataCheck(sessionStart)) return()

  sessionDurSec <- difftime(Sys.time(),sessionStart,units="secs")
  sessionPosix <- .POSIXct(sessionDurSec,tz="GMT")
  res$H <- format(.POSIXct(sessionPosix,tz="GMT"),"%H")
  res$M <- format(.POSIXct(sessionPosix,tz="GMT"),"%M")
  res$S <- format(.POSIXct(sessionPosix,tz="GMT"),"%S")

  return(res)

}

#' Trim string at given position minus and put ellipsis if needed
#' @param str String to trim if needed
#' @param n Maximum allowed position. If number of character exceed this, a trim will be done
#' @return Trimed string
#' @export
mxShort <- function(str="",n=10){
  stopifnot(n>=4)
  if(nchar(str)>n){
    sprintf("%s...",strtrim(str,n-3))
}else{
  return(str)
}
}
