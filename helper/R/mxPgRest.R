#' Get vector tile layer (PostGIS table) from PGRestAPI
#' @param protocol E.g. http
#' @param url Server url (without http://), default = "localhost".
#' @param port Server port number, default = 3000
#' @export
vtGetLayers<-function(protocol="http",url="localhost",port=3030,grepExpr="",nTry=5){

  urlFetch <- sprintf("%s://%s:%s/services/tables?format=json",protocol,url,port)

  vt = character(0)

  layerFetched <- FALSE

  for(i in 1:nTry){
    if(!layerFetched){
      tryCatch({
        vt = jsonlite::fromJSON(urlFetch)
        layerFetched <- TRUE
      },error=function(e){
        tr <- ifelse(i>1,"tries","try")
        cat(paste(Sys.time(),"PGrestAPI: error after ",i,tr,"caused by:",e$message,"\n"))
        if(i < nTry){
          Sys.sleep(i)
          return(NULL)
        }else{
          stop(paste("Fail after",i,tr," caused by:",e$message))
        }
      },finally={closeAllConnections()}
        )
    }
  }

  if(nchar(grepExpr)>0) vt <- grep(grepExpr,vt,value=TRUE)
  return(vt)
}

#' Get available fields/columns from a layer/table
#' @param protocol E.g. http
#' @param url Server url (without http://), default = "localhost"
#' @param port Server port number, default = 3000
#' @param table Table name.
#' @export
vtGetColumns<-function(protocol="http",url='localhost',port=3030,table=NULL,exclude=NULL){
  if(missing(table))stop('table paramater missing')
  if(isTRUE(nchar(table)<1) || is.null(table)) return()
  url<-sprintf("%s://%s:%s/services/tables/%s?format=json",protocol,url,port,table)
  res<-jsonlite::fromJSON(url)
  vtEnabled<-isTRUE(grep('Vector Tile Service',res$supportedOperations$name)>0)
  if(!vtEnabled)return()
  res <- res$columns

  if(!is.null(exclude)){
    if(is.vector(exclude))
      res <- res[!res$column_name %in% exclude,]
  }
  return(res)
}

#' Get layer/table and available field/column combined in a list
#' @param protocol E.g. http
#' @param url Server url (without http://), default = "localhost"
#' @param port Server port number. default = 3000
vtDataList<-function(protocol="http",url='localhost',port=3030){
  res=list()
  tn<-vtGetLayers(protocol=protocol,url=url,port=port)
  if(length(tn)<0)return(null)
  for(t in tn){
    cols<-list(vtGetColumns(protocol=protocol,url=url,port=port,table=t))
    names(cols)<-t
    res<-c(res,cols)
  }
  return(res)
}

