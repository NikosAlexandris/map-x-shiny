


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

#' Set map panel mode
#' @param session Shiny session
#' @param mode Map panel mode. In mapViewCreator, mapStoryCreator, mapExplorer
#' @param title Optionnal title to be returned.
#' @return title string
#' @export
mxSetMapPanelMode <- function(session=shiny::getDefaultReactiveDomain(),mode=c("mapViewsConfig","mapViewsCreator","mapStoryCreator","mapViewsExplorer"),title=NULL){
  mode = match.arg(mode)
  mxDebugMsg(paste("Set mode to : ", mode))
  jsCode <- sprintf("mxPanelMode.mode ='%s';",mode)
  session$sendCustomMessage(type="jsCode",list(code=jsCode))
  return(list(title=title,mode=mode))
}


#' print debug message
#' this function could propulate log file.
#' @param m Message to be printed
#' @return NULL
#' @export
mxDebugMsg <- function(m=""){ 
  options(digits.secs=6)
  cat(paste0("[",Sys.time(),"]",m,'\n'))
}


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
    #print(paste("mxCatch: ",title))
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


##' Hide layer
##' @param session Shiny session
##' @param layer Leaflet.MapboxVectorTile layer group object name
##' @export
#setLayerVisibility <- function(session=shiny:::getDefaultReactiveDomain(),views="leafletvtGroup",status="leafletvtVisible",group=NULL,visible=TRUE){
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
#

#' Set given layer opacity
#' @param session Shiny session
#' @param layer Leaflet.MapboxVectorTile layer group object name
#' @param opacity Opacits
#' @export
setLayerOpacity <- function(session=shiny:::getDefaultReactiveDomain(),layer="leafletvtGroup",group=NULL,opacity=1){
  if(!noDataCheck(group)){
    jsCode = sprintf("if(typeof %s !== 'undefined'){%s.%s.setOpacity(%s)};",layer,layer,group,opacity)
    mxDebugMsg(jsCode)
  session$sendCustomMessage(
    type="jsCode",
    list(code=jsCode)
    )
  }
}





#' Set zIndex
#' @param session Shiny session
#' @param layer Leaflet.MapboxVectorTile layer group object name
#' @param zIndex zIndex of the group
#' @export
setLayerZIndex <- function(session=getDefaultReactiveDomain(),layer="leafletvtGroup",group=NULL,zIndex=15){
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
# example:
#amAccordionGroup(id='superTest',
#  itemList=list(
#    'a'=list('title'='superTitle',content='acontent'),
#    'b'=list('title'='bTitle',content='bContent'))
#  )
#


# load external ui file
loadUi<-function(path){
  source(path,local=TRUE)$value
}


#' Retrieve map views table 
#' @param dbInfo Named list with dbName,host,port, user and password
#' @param table Table name containing views info
#' @param validated Boolean filter validated dataset. Default = TRUE
#' @param archived Boolean filter to get archived data. Default =FALSE
#' @param country ISO 3 code to filter country. 



  mxGetViewsList <- function(dbInfo=NULL, table=NULL,validated=TRUE,archived=FALSE,country="AFG"){
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
      }
    },finally=dbDisconnect(con)) 
  }


mxFileInput<-function (inputId, label, fileAccept=NULL, multiple=FALSE){
  inputTag<-tags$input(
    type='file',
    class='upload',
    accept=paste(fileAccept,collapse=','),
    id=inputId,
    name=inputId)
  if(multiple) inputTag$attribs$multiple='multiple'
  spanTag<-tags$span(label)
  inputClass<-tags$label(
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

mxActionButtonToggle <- function(id,session=shiny:::getDefaultReactiveDomain(),disable=TRUE) {
  addDefault<-paste0("$('#",id,"').addClass('btn-default').removeClass('btn-danger').attr('disabled',false);")
  addDanger<-paste0("$('#",id,"').addClass('btn-danger').removeClass('btn-default').attr('disabled',true);")

  val<-ifelse(disable,addDanger,addDefault)
  session$sendCustomMessage(
    type="jsCode",
    list(code=val)
    )
}


remoteCmd <- function(host=NULL,user=NULL,port=NULLL,cmd=NULL){
  if(!is.null(cmd)){
   res =  system(sprintf("ssh -p %s %s@%s %s",port,user,host,cmd),intern=TRUE)
  }
  return(res)
}


 



#' Write spatial data frame to postgis
#' Taken from https://philipphunziker.wordpress.com/2014/07/20/transferring-vector-data-between-postgis-and-r/
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


#' Add palette function
#' sty leafletvt style
#' pal name of palette to use
#'@export
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

mxSetStyle<-function(session=shiny:::getDefaultReactiveDomain(),style,status){

       if(!noDataCheck(style) && !any(sapply(style,is.null))){
      vtOk = isTRUE(style$group == status$grp && grep(style$layer,status$lay)>0)
      if(!vtOk){
        mxDebugMsg("style vs status conflict: return NULL")
        return()
      }
      if(vtOk){
        mxDebugMsg("Update layer style")
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
        mxDebugMsg("Begin style")
        start = Sys.time()
        legendId = sprintf("%s_legends",grp)
        proxyMap <- leafletProxy("mapxMap")
        if(is.null(tit))tit=lay
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
        jsColorsPalette <- sprintf("var colorsPalette=%s;",toJSON(col,collapse=""))
        jsDataCol <- sprintf("var dataColumn ='%s' ;",var)
        jsOpacity <- sprintf("var opacity =%s ;",opa)
        jsSize <- sprintf("var size =%s; ", sze)
        jsUpdate <- sprintf("leafletvtGroup.%s.setStyle(updateStyle,'%s');",grp,paste0(lay,"_geom"))

        jsStyle = "updateStyle = function (feature) {
        var style = {};
        var selected = style.selected = {};
        var type = feature.type;
        var defaultColor = 'rgba(0,0,0,0)';
        var dataCol = defaultColor;
        var val = feature.properties[dataColumn];
        if( typeof(val) != 'undefined'){ 
          var dataCol = hex2rgb(colorsPalette[val],opacity);
          if(typeof(dataCol) == 'undefined'){
            dataCol = defaultColor;
          }
        }
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
            size: 1
          };
          selected.color = 'rgba(255,0,0,0)';
          selected.outline = {
            color: 'rgba(255,0,0,0.9)',
            size: size
          };
          break;
        };
        return style;

      };
      "
      # jsStyle = "updateStyle = function(){s={};s.color=randomHsl(0.8); return s;};"
      #jsTimeBefore = "var d= new Date(); console.log('Time before style' + d + d.getMilliseconds());"
      #jsTimeAfter = "var d= new Date(); console.log('Time after style' + d + d.getMilliseconds());"
      jsCode = paste(
        jsColorsPalette,
        jsDataCol,
        jsOpacity,
        jsSize,
        jsStyle,
        jsUpdate
        )


     # session$sendCustomMessage(type="jsCode",list(code=jsTimeBefore))
      session$sendCustomMessage(type="jsCode",list(code=jsCode))
     # session$sendCustomMessage(type="jsCode",list(code=jsTimeAfter))

      #      setLayerZIndex(group=grp,zIndex=15)
      stop <- Sys.time() - start
      mxDebugMsg(paste("End style. Timing=",stop))
      cat(paste(paste0(rep("-",80),collapse=""),"\n"))
        }
        }
        }

