#
#
#
#
#vtGetLayers<-function(url="localhost",port=3000){
#url<-sprintf("http://%s:%s/services/tables?format=json",url,port)
#jsonlite::fromJSON(url)
#}
#
#vtGetColumns<-function(url='localhost',port=3000,table=NULL){
#  if(missing(table))stop('table paramater missing')
#  url<-sprintf("http://%s:%s/services/tables/%s?format=json",url,port,table)
#  res<-jsonlite::fromJSON(url)
#  vtEnabled<-isTRUE(grep('Vector Tile Service',res$supportedOperations$name)>0)
#  if(!vtEnabled)return()
#  res$columns
#}
#
#vtDataList<-function(url='localhost',port=3000){
#  res=list()
#  tn<-vtGetLayers(url=url,port=port)
#  if(length(tn)<0)return(null)
#  for(t in tn){
#    cols<-list(vtGetColumns(url=url,port=port,table=t))
#    names(cols)<-t
#    res<-c(res,cols)
#  }
#  return(res)
#}
#
#
#listToHtml<-function(listInput,htL='',h=2, exclude=NULL){
#    hS<-paste0('<H',h,'><u>',collapse='') #start
#  hE<-paste0('</u></H',h,'>',collapse='') #end
#    h=h+1 #next
#    if(is.list(listInput)){
#          nL<-names(listInput)
#        nL <- nL[!nL %in% exclude]
#            htL<-append(htL,'<ul>')
#            for(n in nL){
#                    #htL<-append(htL,c('<li>',n,'</li>'))
#                    htL<-append(htL,c(hS,n,hE))
#                  subL<-listInput[[n]]
#                        htL<-listToHtml(subL,htL=htL,h=h,exclude=exclude)
#                      }
#                htL<-append(htL,'</ul>')
#              }else if(is.character(listInput) || is.numeric(listInput)){
#                    htL<-append(htL,c('<li>',paste(listInput,collapse=','),'</li>'))
#                }
#      return(paste(htL,collapse=''))
#}
#
#
#
#dbGetSp <- function(dbInfo,query) {
#  if(!require('rgdal')|!require(RPostgreSQL))stop('missing rgdal or RPostgreSQL')
#  d <- dbInfo
#  tmpTbl <- sprintf('tmp_table_%s',round(runif(1)*1e5))
#  dsn <- sprintf("PG:dbname='%s' host='%s' port='%s' user='%s' password='%s'",
#    d$dbname,d$host,d$port,d$user,d$password
#    )
#  drv <- dbDriver("PostgreSQL")
#  con <- dbConnect(drv, dbname=d$dbname, host=d$host, port=d$port,user=d$user, password=d$password)
#  tryCatch({
#    sql <- sprintf("CREATE UNLOGGED TABLE %s AS %s",tmpTbl,query)
#    res <- dbSendQuery(con,sql)
#    nr <- dbGetInfo(res)$rowsAffected
#    if(nr<1){
#      warning('There is no feature returned.'); 
#      return()
#    }
#    sql <- sprintf("SELECT f_geometry_column from geometry_columns WHERE f_table_name='%s'",tmpTbl) 
#    geo <- dbGetQuery(con,sql)
#    if(length(geo)>1){
#      tname <- sprintf("%s(%s)",tmpTbl,geo$f_geometry_column[1])
#    }else{
#      tname <- tmpTbl;
#    }
#    out <- readOGR(dsn,tname)
#    return(out)
#  },finally={
#    sql <- sprintf("DROP TABLE %s",tmpTbl)
#    dbSendQuery(con,sql)
#    dbClearResult(dbListResults(con)[[1]])
#    dbDisconnect(con)
#  })
#}
#
#
#
#
#dbGetGeoJSON<-function(dbInfo,query){
#  dsn <- sprintf("PG:dbname='%s' host='%s' port='%s' user='%s' password='%s'",
#    d$dbname,d$host,d$port,d$user,d$password
#    )
#  tmp <- paste0(tempfile(),".geojson")
#  print(tmp)
#  system(sprintf("ogr2ogr -f GeoJSON '%s' '%s' -sql '%s' -t_srs '%s'",tmp,dsn,query,"EPSG:4326"))
#  return(jsonlite::fromJSON(tmp))
#}
#
