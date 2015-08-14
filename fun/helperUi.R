

lorem <- "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Vestibulum posuere turpis eu tempus aliquet. Etiam id quam sapien. Suspendisse fermentum est non augue interdum pulvinar. Lorem ipsum dolor sit amet, consectetur adipiscing elit. Curabitur maximus in quam eget efficitur. Etiam tempor, tortor nec tristique ultrices, diam justo finibus risus, quis auctor urna magna a est. Integer gravida ligula sapien, quis mattis justo viverra eget. Sed semper vulputate quam. Nam vehicula tellus nec justo pretium consequat. Nunc accumsan mi vel felis tristique aliquet.

Praesent id lacus vel metus gravida sollicitudin ut quis dui. Quisque lobortis tristique eleifend. Duis feugiat justo vel arcu tincidunt, quis vehicula purus posuere. Sed tortor arcu, varius eget sollicitudin vitae, sodales et risus. Curabitur euismod elit eu pulvinar ullamcorper. Vivamus pulvinar metus nec dolor pretium molestie. Praesent convallis porttitor augue, et elementum eros commodo id."




mxTogglePanel <- function(session=shiny::getDefaultReactiveDomain(),id){
  jsToggle <- paste0("$('#",paste(id,"content",sep="_"),"').toggle();")
 session$sendCustomMessage(
    type="jsCode",
    list(code=jsToggle)
    )
}


mxPanel<- function(id="default",title=NULL,subtitle=NULL,html=NULL,listActionButton=NULL,background=TRUE,defaultButtonText="OK",style=NULL,class=NULL,hideCloseButton=FALSE,draggable=TRUE){ 
  #classVect <- c('panel-modal',sprintf("panel-%s",id))
  #classModal <- paste(classVect,collapse=" ")
  
  classModal = "panel-modal"
  idBack = paste(id,"background",sep="_")
  idContent = paste(id,"content",sep="_")
  # NOTE: .remove() breaks the shiny input binding. Using .hide() and no unique id.
  #jsHide <- paste0("$('",paste0(".",classVect,collapse=" "),"').toggle()")
  jsHide <- paste0("$('#",idContent,"').toggle();$('#",idBack,"').toggle()")

  # If NULL Set default button action to "close" panel, with custom text
  if(is.null(listActionButton))listActionButton=list(
    tags$button(onclick=jsHide,defaultButtonText,class="btn btn-default")
    )



  
  # if explicit FALSE is given, remove modal button. 
  if(isTRUE(is.logical(listActionButton) && !isTRUE(listActionButton)))listActionButton=NULL


  if(hideCloseButton){
    closeButton=NULL
  }else{
    closeButton=a(href="#", onclick=jsHide,style="float:right;color:black",icon('times'))
  }

print(paste("style for",idContent,':',style))
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



mxUpdatePanel <- function(panelId=NULL,session=shiny:::getDefaultReactiveDomain(),...){
  session$output[[panelId]] <- renderUI(mxPanel(id=panelId,...))
}

mxPanelAlert <- function(title=c("error","warning","message"),subtitle=NULL,message=NULL,listActionButton=NULL){ 
  title = match.arg(title)
  switch(title,
    'error'={title=h2(icon("exclamation-circle"),toupper(title))},
    'warning'={title=h2(icon("exclamation-triangle"),toupper(title))},
    'message'={title=h2(icon("info-circle"),toupper(title))} 
    )
  mxPanel(class="panel-overall",title=title,subtitle=subtitle,html=message,listActionButton=listActionButton)
}


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


#' Set given layer opacity
#' @param session Shiny session
#' @param layer Leaflet.MapboxVectorTile layer group object name
#' @param opacity Opacits
#' @export
setLayerOpacity <- function(session=shiny:::getDefaultReactiveDomain(),layer="leafletvtGroup",opacity=1){
  session$sendCustomMessage(
    type="jsCode",
    list(code=sprintf("if(typeof %s !== 'undefined'){for(key in %s){%s[key].setOpacity(%s)}};",layer,layer,layer,opacity))
    )
}



#' Toggle html element by class
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
#' @export
removeModal <- function(){
  removeClass(class="panel-modal")
}

#' Random name generator
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


#' Substitute ponctuation with given sep
#' @param str String to evaluate
#' @param sep Replace separator
#' @param rmTrailingSep Logical argument : no trailing separator returned
#' @param rmLeadingSep Logical argument : no leading separator returned
#' @param rmDuplicateSep Logical argument : no consecutive separator returned
#' @export
subPunct<-function(str,sep='_',rmTrailingSep=T,rmLeadingSep=T,rmDuplicateSep=T){
  str<-gsub("'",'',iconv(str, to='ASCII//TRANSLIT'))
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


#' Test for 

dbTestConnection <- function(dbInfo=NULL){
  if(is.null(dbInfo)) stop('Missing arguments')
  testOut = FALSE
  d <- dbInfo

  tryCatch({
  drv <- dbDriver("PostgreSQL")
  con <- dbConnect(drv, dbname=d$dbname, host=d$host, port=d$port,user=d$user, password=d$password)
  con <- dbConnect(drv)
  
  })

}



#' Get layer center
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


