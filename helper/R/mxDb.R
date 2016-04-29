

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
  con <- dbConnect(
    drv, 
    dbname=d$dbname, 
    host=d$host, 
    port=d$port,
    user=d$user, 
    password=d$password
    )

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
dbGetGeoJSON<-function(dbInfo,query,fromSrid="4326",toSrid="4326",asList=FALSE){
  # NOTE: check package geojsonio for topojson and geojson handling.
  # https://github.com/ropensci/geojsonio/issues/61
  d <- dbInfo

  dsn <-gsub("\n|\\s+"," ",sprintf(
    "dbname='%1$s'
    host='%2$s'
    port='%3$s'
    user='%4$s'
    password='%5$s'",
    d$dbname,
    d$host,
    d$port,
    d$user,
    d$password
    ))
  
  tmp <- paste0(tempfile(),".geojson")

  cmd <-gsub("\n|\\s+"," ",sprintf(
      "ogr2ogr -f GeoJSON
      %2$s
      PG:\"%1$s\"
      -sql '%3$s'
      -s_srs 'EPSG:%4$s'
      -t_srs 'EPSG:%5$s'",
      dsn,
      tmp,
      query,
      fromSrid,
      toSrid
      )
    )
  
  system(cmd)

 if(asList){
  return(jsonlite::fromJSON(tmp))
 }else{
   return(tmp)
 }
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

      ext <- mxDbGetQuery(q)[[1]] %>% 
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
      suppressWarnings({
      res <- mxDbGetQuery(sqlWhere)
      })
      
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

        columnExists <- nrow( mxDbGetQuery(q) ) > 0 

        if(!columnExists){
          message(paste("column",column," does not exist in ",table))
          return()
        }

        nR <- mxDbGetQuery(sprintf(
            "SELECT count(*) 
            FROM %s 
            WHERE %s IS NOT NULL"
            ,table
            ,column
            )
          )[[1]]

        nN <- mxDbGetQuery(sprintf(
            "SELECT count(*) 
            FROM %s 
            WHERE %s IS NULL"
            ,table
            ,column
            )
          )[[1]]
        nD <- mxDbGetQuery(sprintf(
            "SELECT COUNT(DISTINCT(%s)) 
            FROM %s 
            WHERE %s IS NOT NULL"
            ,column
            ,table
            ,column
            )
          )[[1]]

        val <- mxDbGetQuery(sprintf("
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

      
      mxDbGetQuery(query)[[2]] %>%
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

    ext <- mxDbGetQuery(q)[[1]]

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



#' Add geojson list or file to db postgis
#' @param geojsonList list containing the geojson data
#' @param geojsonPath path the geojson
#' @param dbInfo dbInfo object containgin pass,user, .... 
#' @param tableName Name of the postgis layer / table 
dbAddGeoJSON  <-  function(geojsonList=NULL,geojsonPath=NULL,dbInfo=NULL,tableName=NULL,archiveIfExists=T,archivePrefix="mx_archives"){


      # NOTE : no standard method worked.
      # rgdal::writeOGR (require loading in r AND did not provide options AND did not allow mixed geometry) or gdalUtils::ogr2ogr failed (did not set -f option!).
    
  gL <- geojsonList
  gP <- geojsonPath
  tN <- tableName
  d <- dbInfo
  timestamp <- format(Sys.time(),"%Y_%m_%d_%H_%M_%S")
  aN <- paste0(archivePrefix,"_",tN,"_",timestamp)
  tE <- mxDbExistsTable(d,tN)
  aE <- mxDbExistsTable(d,aN)


  if(!is.null(gL) && typeof(gL) == "list"){
    gP <- tempfile(fileext=".GeoJSON")
    write(jsonlite::toJSON(gL,auto_unbox=TRUE),gP)
  }

  #
  # Stop if file does not exists
  #
  stopifnot(file.exists(gP))
  #
  # overwrite handling
  #
  if(tE && isTRUE(archiveIfExists) && aE){

      aNameTable <- aN
      aNameSeq <- paste0(aN,"_seq")
      aNameIdx <- paste0(aN,"_idx")
      aNamePkey <- paste0(aN,"_pkey")

      qdb <- sprintf("
        ALTER TABLE IF EXISTS %1$s 
        RENAME TO %2$s;
        ALTER SEQUENCE IF EXISTS %1$s_gid_seq 
        RENAME TO %3$ ;
        ALTER INDEX IF EXISTS %1$s_geom_geom_idx
        RENAME TO %4$ ;
        ALTER INDEX IF EXISTS %1$s_pkey
        RENAME TO %5$s ;
        ",
        tN,
        aNameTable,
        aNameIdx,
        aNameSeq,
        aNamePkey
        )
  
      mxDbGetQuery(qdb) 
  }
  if(aE){
    stop("Archive requested but already existing ! ArchiveName =  %a",aN)
  }else{

  #
  # Import into db
  #
  tD <- sprintf("PG:dbname='%s' host='%s' port='%s' user='%s' password='%s'",
    d$dbname,d$host,d$port,d$user,d$password
    )
  cmd = sprintf(
    "ogr2ogr
    -t_srs 'EPSG:4326'
    -s_srs 'EPSG:4326'
    -geomfield 'geom'
    -lco FID='gid'
    -lco GEOMETRY_NAME='geom'
    -lco SCHEMA='public'
    -f 'PostgreSQL'
    -overwrite
    -nln '%1$s'
    -nlt 'PROMOTE_TO_MULTI'
    '%2$s'
    '%3$s'
    OGRGeoJSON
    ",tN,tD,gP)
    cmd <- gsub("\n\\s+"," ",cmd)

    # 
    # Execute command
    #
  system(cmd,intern=TRUE)
  }



}






#' Get query result from postgresql
#'
#' Shortcut to create a connection, get the result of a query and close the connection, using a dbInfo list. 
#'
#' @param dbInfo Named list with dbName,host,port,user and password
#' @param SQL query
#' @export
mxDbGetQuery <- function(query,stringAsFactors=FALSE,dbInfo=mxConfig$dbInfo){
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
    res <- mxDbGetQuery(query)

    return(res)
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



