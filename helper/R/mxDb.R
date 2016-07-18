
#' Experimental db conection in config list
#' 
#' @export
mxDbAutoCon <- function(){

  res <- NULL
  oldCon <- list()

  tryCon <- try(silent=T,{

    maxCon <- mxConfig$dbMaxConnections 
       # get list of existing connection
    drv <- dbDriver("PostgreSQL")
    oldCon <- dbListConnections(drv)
    createNew <- TRUE
    oldConLength <- length(oldCon)

    #mxDebugMsg(sprintf("mxDbAutoCon : found %s connections",oldConLength))
    if(oldConLength >= maxCon){
      # select randomly one connection NOTE: What if there is pending rows on this connection ?
      res <- sample(oldCon,1)[[1]]
      if(!isPostgresqlIdCurrent(res)){
        #mxDebugMsg("mxDbAutoCon : selected connection is not valid, try to set a new one")
        createNew = TRUE
        postgresqlCloseConnection(res)
      }else{
      createNew = FALSE
      }
    }

    if(createNew){
      #mxDebugMsg("mxDbAutoCon : create a new connection")
      # extract and control dbInfo list
      d <- mxConfig$dbInfo
      allParam <- all(c("dbname","host","port","user","password") %in% names(d))
      allFilled <- all(!sapply(d,noDataCheck))
      stopifnot(all(allParam,allFilled))
      # create a new connection
      res <- dbConnect(drv, dbname=d$dbname, host=d$host, port=d$port,user=d$user, password=d$password)
      if(is.null(res)) stop()
    }
  })

  if("try-error" %in% class(tryCon)){
    mxDebugMsg(tryCon)
    stop("mxDbAutoCon can't connect to the database")
  }

    return(res)
}



#' Get query result from postgresql
#'
#' Wrapper to execute a query 
#'
#' @param query SQL query
#' @export
mxDbGetQuery <- function(query,stringAsFactors=FALSE,onError=function(x){stop(x)}){
  res <- NULL
  data <- data.frame()

  tryCatch({    
    suppressWarnings({

      res <- postgresqlExecStatement(mxDbAutoCon(), gsub("\n","",query))
      if(dbGetInfo(res)$isSelect!=0){
        temp <- postgresqlFetch(res)
        if( dbGetRowCount(res) > 0 ){ 
          data <- temp
        }
      }
    })
  },
  error = onError
  )

  on.exit({ 
    mxDbClearAll()
  })

  return(data)

}

#' Update a single value of a table
#' @param table Table to update
#' @param column Column to update
#' @param idCol Column of identification
#' @param id Identification value
#' @param value Replacement value
#' @param expectedRowsAffected Number of row expected to be affected. If the update change a different number of row than expected, the function will rollback
#' @return Boolean worked or not
#' @export
mxDbUpdate <- function(table,column,idCol="id",id,value,jsonPath=NULL,expectedRowsAffected=1){   


  # explicit check
  stopifnot(mxDbExistsTable(table))
  stopifnot(column %in% mxDbGetColumnsNames(table))
  # implicit check
  stopifnot(!noDataCheck(id))
  stopifnot(!noDataCheck(idCol))

  # get connection object
  con <- mxDbAutoCon()

        if(!is.null(jsonPath)){
          # if value has no json class, convert it (single value update)
          if(isTRUE(!"json" %in% class(value))){
            value <- mxToJsonForDb(value)
          }
          # json update

          jsonPath <- paste0("{",paste0(paste0("\"",jsonPath,"\""),collapse=","),"}")

          query <- sprintf("
              UPDATE %1$s
              SET \"%2$s\"= (
              SELECT jsonb_set(
                (
                  SELECT \"%2$s\" 
                  FROM %1$s
                  WHERE \"%4$s\"='%5$s'
                  ) ,
                '%6$s',
                '%3$s'
                )
              ) 
            WHERE \"%4$s\"='%5$s'",
            table,
            column,
            value,
            idCol,
            id,
            jsonPath
            )

        }else{
          # if it's a list, convert to json
          if(is.list(value)) value <- mxToJsonForDb(value)
          # standard update
          query <- gsub("\n","",sprintf("
              UPDATE %1$s
              SET \"%2$s\"='%3$s'
              WHERE \"%4$s\"='%5$s'",
              table,
              column,
              value,
              idCol,
              id
              ))
        }


      res <- try(silent=T,{
        dbGetQuery(con,"BEGIN TRANSACTION")
        rs <- dbSendQuery(con,query)   
        ra <- dbGetInfo(rs,what="rowsAffected")[[1]]
        if(isTRUE(is.numeric(expectedRowsAffected) && isTRUE(ra != expectedRowsAffected)) ){
          stop(
            sprintf(
              "Error, number of rows affected does not match expected rows affected %s vs %s",
              ra,
              expectedRowsAffected
              )
            )
        }else{
          mxDebugMsg(sprintf("Number of row affected=%s",ra))
          dbCommit(con)
        }
      })

    if("try-error" %in% res){
      dbRollback(con)
      res <- FALSE
    }else{
      res <- TRUE
    }
    return(res)
}






#' Transfert postgis feature by sql query to sp object
#' @param query PostGIS spatial sql querry.
#' @return spatial object.
#' @export
mxDbGetSp <- function(query) {
  if(!require('rgdal')|!require(RPostgreSQL))stop('missing rgdal or RPostgreSQL')

  d<- mxConfig$dbInfo
  tmpTbl <- sprintf('tmp_table_%s',round(runif(1)*1e5))
  dsn <- sprintf("PG:dbname='%s' host='%s' port='%s' user='%s' password='%s'",
    d$dbname,d$host,d$port,d$user,d$password
    )
  
  con <- mxDbAutoCon()

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
      mxDbClearAll()
    })

    return(out)
  })

}


#' Geojson from postGIS base
#' @param query PostGIS spatial sql querry.
#' @return geojson list
#' @export
mxDbGetGeoJSON<-function(query,fromSrid="4326",toSrid="4326",asList=FALSE){

  # NOTE: check package geojsonio for topojson and geojson handling.
  # https://github.com/ropensci/geojsonio/issues/61

  d<- mxConfig$dbInfo
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
#' @param table Table/layer from which extract extent
#' @param geomColumn set geometry column
#' @return extent
#' @export
mxDbGetLayerExtent<-function(table=NULL,geomColumn='geom'){

  if(is.null(table)) stop('Missing table name')


  if(mxDbExistsTable(table)){

    q <- sprintf("SELECT ST_Extent(%s)::text as table_extent FROM %s;",geomColumn,table)

    res <- mxDbGetQuery(q)$table_extent %>%
      gsub(" ",",",.) %>%
      gsub("[a-zA-Z]|\\(|\\)","",.)%>%
      strsplit(.,",")%>%
      unlist()%>%
      as.numeric()%>%
      as.list()

    names(res)<-c("lng1","lat1","lng2","lat2")

    return(res)
  }
}

#' Extract list of layer for one country, for given visibility or userid
#' @param project Project or iso3 country code
#' @param visibility Groupe/role set as target
#' @param userId Integer user id
#' @export
mxDbGetLayerList <- function(project=NULL,visibility="public",userId=NULL){

  stopifnot(!noDataCheck(project))
  stopifnot(!noDataCheck(userId))
  stopifnot(!noDataCheck(visibility))

  visibility <- paste(paste0("'",visibility,"'"),collapse=",")



  sql <- gsub("\n","",sprintf(
      "SELECT layer 
      FROM mx_layers 
      WHERE country='%1$s' AND
      ( visibility ?| array[%2$s] OR editor = '%3$s' )",
      project,
      visibility,
      userId
      ))

  layers <- mxDbGetQuery(sql)$layer
  orphan <- layers[!layers %in% mxDbListTable()]

  layers <- layers[layers %in% mxDbListTable()]

  if(!noDataCheck(orphan)){
    sapply(orphan,mxDbDropLayer)
  }
  
  return(layers)

}


#' @export
mxDbGetValByCoord <- function(table=NULL,column=NULL,lat=NULL,lng=NULL,geomColumn="geom",srid="4326",distKm=1){
  if(
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
#' @param table Table/layer from which extract extent
#' @param column Column/Variable on wich extract summary
#' @export
  mxDbGetColumnInfo<-function(table=NULL,column=NULL){

    if(noDataCheck(table) || noDataCheck(column) || isTRUE(column=='gid'))return() 


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
#' @param table Table/layer from which extract extent
#' @param geomColumn set geometry column
#' @return extent
#' @export
mxDbGetLayerCentroid<-function(table=NULL,geomColumn='geom'){
  if(is.null(table)) stop('Missing arguments')
  
    if(mxDbExistsTable(table)){
      
      query <- sprintf(
        "SELECT ST_asText(ST_centroid(ST_union(%s)))::text 
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

      return(ext)
    }

}

#' Get query extent, based on a pattern matching (character)
#' 
#' Search for a value in a  column (character data type) and return the extent if something is found.
#'
#' @param table Table/layer from which extract extent
#' @param geomColumn set geometry column
#' @return extent
#' @export
mxDbGetFilterCenter<-function(table=NULL,column=NULL,value=NULL,geomColumn='geom',operator="="){

  if(mxDbExistsTable(table)){
    valueOrig <- gsub("'","''",value)
    valueEscape <- paste0("(E",paste0("\'",valueOrig,"\'",collapse=","),")")
    if(length(value)>1){
      operator <- "in"
    }

    q = sprintf("
      SELECT ST_Extent(%1$s)::text as data_extent 
      FROM (SELECT %1$s FROM %2$s WHERE %3$s %5$s %4$s ) t
      WHERE ST_isValid(%1$s)",
      geomColumn,
      table,
      column,
      valueEscape,
      operator
      )

    ext <- mxDbGetQuery(q)$data_extent

    if(noDataCheck(ext))return(NULL)


    res <- ext %>%
      gsub(" ",",",.) %>%
      gsub("[a-zA-Z]|\\(|\\)","",.)%>%
      strsplit(.,",")%>%
      unlist()%>%
      as.numeric()%>%
      as.list()

    names(res)<-c('lng1', 'lat1', 'lng2', 'lat2')

    return(res)
  }

}



#' Add geojson list or file to db postgis
#' @param geojsonList list containing the geojson data
#' @param geojsonPath path the geojson
#' @param tableName Name of the postgis layer / table 
mxDbAddGeoJSON  <-  function(geojsonList=NULL,geojsonPath=NULL,tableName=NULL,archiveIfExists=T,archivePrefix="mx_archives"){


  dbInfo<- mxConfig$dbInfo
  d <- dbInfo

      # NOTE : no standard method worked.
      # rgdal::writeOGR (require loading in r AND did not provide options AND did not allow mixed geometry) or gdalUtils::ogr2ogr failed (did not set -f option!).
    
  gL <- geojsonList
  gP <- geojsonPath
  tN <- tableName
  timestamp <- format(Sys.time(),"%Y_%m_%d_%H_%M_%S")
  aN <- paste0(archivePrefix,"_",tN,"_",timestamp)
  tE <- mxDbExistsTable(tN)
  aE <- mxDbExistsTable(aN)


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
 

    test <- try(silent=TRUE,{
      tD <- sprintf("PG:dbname=%s host=%s port=%s user=%s password=%s",
        d$dbname,d$host,d$port,d$user,d$password
        )

      cmd = sprintf(
        "ogr2ogr \\
        -t_srs \"EPSG:4326\" \\
        -s_srs \"EPSG:4326\" \\
        -geomfield \"geom\" \\
        -lco FID=\"gid\" \\
        -lco GEOMETRY_NAME=\"geom\" \\
        -lco SCHEMA=\"public\" \\
        -f \"PostgreSQL\" \\
        -overwrite \\
        -nln \"%1$s\" \\
        -nlt \"PROMOTE_TO_MULTI\" \\
        \'%2$s\' \\
        \'%3$s\' \\
        \"OGRGeoJSON\""
        ,tN
        ,tD
        ,gP
        )

      # 
      # Execute command
      #
      system(cmd,intern=TRUE)
    })

    if("try-catch" %in% class(test)) stop("Something went wrong during the transfert to the database.")

  }



}






#' List existing table from postgresql
#'
#' Shortcut to create a connection, get the list of table and close the connection, using a dbInfo list. 
#'
#' @param dbInfo Named list with dbName,host,port,user and password
#' @export
mxDbListTable<- function(){
  res <- dbListTables(mxDbAutoCon())
  on.exit({
    mxDbClearAll()
  })
  return(res)
}

#' Check if table exists in postgresql
#'
#' Shortcut to create a connection, and check if table exists. 
#'
#' @param table Name of the table to check
#' @export
mxDbExistsTable<- function(table){
  res <- dbExistsTable(mxDbAutoCon(),table)

  on.exit({
    mxDbClearAll()
  })

  return(res)
}



#' List existing column from postgresql table
#'
#' Shortcut to get column name for a table
#'
#' @param dbInfo Named list with dbName,host,port,user and password
#' @export
mxDbGetColumnsNames <- function(table){
  query <- sprintf("select column_name as res from information_schema.columns where table_schema='public' and table_name='%s'",
    table
    )
  res <- mxDbGetQuery(query)$res

  return(res)
}

#' List existing column type from postgresql table
#'
#' Shortcut to get column type for a table
#'
#' @param table Name of the table to evaluate
#' @export
mxDbGetColumnsTypes <- function(table){
  query <- sprintf("select data_type as res from information_schema.columns where table_schema='public' and table_name='%s'",
    table
    )
  res <- mxDbGetQuery(query)$res
  
  return(res)
}




#' Add data to db
#'
#' 
#'
mxDbAddData <- function(data,table){

  stopifnot(class(data)=="data.frame")
  stopifnot(class(table)=="character")

  tAppend <- FALSE
  tExists <- FALSE
 
  tExists <- mxDbExistsTable(table)

  if(tExists){
    tNam <- sort(tolower(names(data)))
    rNam <- sort(tolower(mxDbGetColumnsNames(table)))
    if(!isTRUE(identical(tNam,rNam))){
      wText <- sprintf("mxDbAddData: append to %1$s. Name(s) not in remote table: '%2$s', remote name not in local table '%3$s'",
        table,
        paste(tNam[!tNam %in% rNam],collapse="; "),
        paste(rNam[!rNam %in% tNam],collapse="; ")
        )
      stop(wText)
    }else{
      tAppend = TRUE
    }
  }
  dbWriteTable(mxDbAutoCon(),name=table,value=data,append=tAppend,row.names=F)
  on.exit({
    mxDbClearAll()
  })
}



mxDbTimeStampFormater <- function(ts){
if(!isTRUE("POSIXct" %in% class(ts))) stop("need a POSIXct object")
ts <- format(ts,"%d-%m-%Y %H:%M:%S")
sprintf("to_timestamp('%1$s','dd-mm-yyyy hh24:mi:ss')",ts)
}


mxDbAddRow <- function(data,table){

  
  tExists <- mxDbExistsTable(table)
  if(!tExists) stop(sprintf("mxDbAddRow : table %s does not exists",table))

  if(!is.list(data)) data <- as.list(data)

  tName <- names(data)
  tClass <- sapply(data,class)
  rName <- mxDbGetColumnsNames(table)

  

  if(!all(tName %in% rName)){
   wText <- sprintf("mxDbAddData: append to %1$s. Name(s) not in remote table: '%2$s', remote name not in local table '%3$s'",
        table,
        paste(tName[!tName %in% rName],collapse="; "),
        paste(rName[!rName %in% tName],collapse="; ")
        )
      stop(wText)

  
  }  # handle date
  dataProc <- lapply(data,function(x){
    switch(class(x)[[1]],
      "character"={
       sprintf("'%1$s'",gsub("'","''",x))

      },
      "POSIXct"={
        mxDbTimeStampFormater(x)
      },
      "logical"={
        tolower(x)
      },
      "numeric"={
        sprintf("%i::numeric",x)
      },
      "integer"={
        sprintf("%i::integer",x)
      },
      sprintf("'%1$s'",x)
      )
  })


  q <- sprintf(
    "INSERT INTO %1$s (%2$s) VALUES (%3$s)",
    table,
    paste(paste0("\"",tName,"\""),collapse=","),
    paste(dataProc,collapse=",")
    )
 
  mxDbGetQuery(q)


}

mxDbAddRowBatch <- function(df,table){

  stopifnot(is.data.frame(df))
  stopifnot(mxDbExistsTable(table))

  for(i in 1:nrow(df)){
  dat <- df[i,]
  mxDbAddRow(dat,table)
  }

}




#' Remove old results from db query
#' @export
mxDbClearAll <- function(){
  suppressWarnings({
    nR <- dbListResults(mxDbAutoCon())
    if(length(nR)>0){
      lapply(nR,dbClearResult)
    }
  })
}



#' Write spatial data frame to postgis
#'
#' Convert spatial data.frame to postgis table. Taken from https://philipphunziker.wordpress.com/2014/07/20/transferring-vector-data-between-postgis-and-r/
#'
#' @param spatial.df  Spatial  data frame object
#' @param schemaname Target schema table
#' @param tablename Target table name
#' @param overwrite Overwrite if exists
#' @param keyCol Set new primary key
#' @param srid Set the epsg code / SRID
#' @param geomCol Set the name of the geometry column
mxDbWriteSpatial <- function(spatial.df=NULL, schemaname="public", tablename, overwrite=FALSE, keyCol="gid", srid=4326, geomCol="geom") {

  library(rgeos)


  con <- mxDbAutoCon()
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

 on.exit({
    mxDbClearAll()
  })
}
#' Get user info
#' @param email user email
#' @param userTable DB users table
#' @return list containing id, email and data from the user
#' @export 
mxDbGetUserInfoList <- function(id=NULL,email=NULL,userTable="mx_users"){
  
  emailIsGiven <- !is.null(email)
  idIsGiven <- !is.null(id)
  col <- "id"

  if(
    (emailIsGiven && idIsGiven) ||
    (!emailIsGiven && !idIsGiven) 
    ) stop("Get user details : one of id or email should be provided.")
 
  if(emailIsGiven) {
    col <- "email"
    id <- paste0("'",email,"'")
  }
  
  quer <- sprintf(
    "SELECT id,email,data::text as data 
    FROM %1$s
    WHERE %2$s = %3$s
    LIMIT 1 
    ",
    userTable,
    col,
    id
    )

  res <- as.list(mxDbGetQuery(quer))
  if(length(res)<1){
   res <- list()
  }else{
   res$data <- jsonlite::fromJSON(res$data,simplifyVector=FALSE)
  }
  class(res) <- c(class(res),"mxUserInfoList")
  return(res)
}



    #WHERE s.role#>>'{\"role\"}' in %2$s 
mxDbGetUserByRoles <- function(roles="user", userTable="mx_users"){
  roles <- paste0("(",paste0("'",roles,"'",collapse=","),")")
  quer <- sprintf("
    SELECT * FROM 
    (  
    SELECT id,email,a.role#>>'{\"project\"}' as project,a.role#>>'{\"role\"}' as role
    FROM (
      SELECT id,email,jsonb_array_elements(data#>'{\"admin\",\"roles\"}') AS role 
      FROM %1$s 
      WHERE jsonb_typeof(data#>'{\"admin\",\"roles\"}') = 'array'
      ) a 
    UNION
       SELECT id,email,key as project, value as role FROM 
    (
      SELECT id,email,(jsonb_each_text(data#>'{\"admin\",\"roles\"}')).* 
      FROM %1$s
    WHERE jsonb_typeof( data#>'{\"admin\",\"roles\"}') = 'object'
    ) b 
    ) c 
    WHERE role  in %2$s 
    "
    , userTable
    , roles
    )
    mxDbGetQuery(quer)
}


#' Get user info based on its role on a given project
#' @param project name e.g. country iso3 code
#' @param roles vector containing names of roles present in mxConfig$roles
#' @param selfId numeric id of the user requesting the list
#' @param userTable name of user table mx_users by default
#' @param cols name of fields to return
#' @return named list containing values from fields in `cols` or empty list
#' @ export
mxDbGetUserInfoByRole_old <- function(project=NULL, roles=NULL,selfId=NULL, userTable="mx_users",cols=c("id","email")){


  #NOTE: find a simpler way of doing this

  quer = character(1)
  useSelf <- "self" %in% roles



  #
  # Is self in roles ? if true, add this rule
  #
  if( ! useSelf ) {
    # by default, return false
    selfIdQuer = "false"
    hasSelf = FALSE
  }else{
    stopifnot(is.numeric(selfId))
    selfIdQuer = sprintf("id = %1$s",selfId)
    hasSelf = TRUE
  }
 
  #
  # Except self, which are the requested roles ?
  #
  roles <- roles[! roles %in% "self"]
  if(length(roles)==0) {
    # by default, return false
    rolesQuer = "false"
    hasRole = FALSE
  }else{ 
    stopifnot(all(roles %in% sapply(mxConfig$roles,`[[`,'role')))
    roles = paste(sprintf("'%s'",roles),collapse=",")




    rolesQuer = sprintf(
      "data#>>'{\"admin\",\"roles\",\"world\"}' in ( %1$s )
    OR data#>>'{\"admin\",\"roles\",\"%2$s\"}' in ( %1$s )
    OR data#>>'{\"admin\",\"roles\",\"%3$s\"}' in ( %1$s ) ",
      roles,
      project,
      toupper(project)
      )
    hasRole = TRUE
  }

  # 
  # Set the where statement
  #
  filtQuer = sprintf("WHERE %1$s OR %2$s"
    ,rolesQuer
    ,selfIdQuer
    )

  #
  # Set the columns to return
  #

  if(length(cols) ==  0) { 
    cols = "*"
  }else{
    stopifnot(all(cols %in% mxDbGetColumnsNames(userTable)))
    cols = paste(cols,collapse=",")
  }

  #
  # Final query
  #

  quer <- gsub("\n","",sprintf(
    "SELECT %1$s FROM %2$s %3$s"
    , cols
    , userTable
    , filtQuer
    ))
  #
  # Execute and retrieve result
  #
  res <- mxDbGetQuery(quer)
  class(res) <- c(class(res),"mxUserTable")
  return(res)
}

#mxDbAddRow <- function(data,table){
  
#' Add 
mxDbCreateUser <- function(
  email=NULL,
  timeStamp=Sys.time(),
  datDefault=mxConfig$defaultDataPublic,
  datSuperuser=mxConfig$defaultDataSuperuser,
  userTable=mxConfig$userTableName
  ){

  stopifnot("POSIXct" %in% class(timeStamp))
  stopifnot(mxEmailIsValid(email))
  stopifnot(mxDbExistsTable(userTable))

  userTable <- mxConfig$userTableName
  dataUserDefault <- mxConfig$defaultDataPublic
  dataUserSuperuser <- mxConfig$defaultDataSuperuser
  userNameDefault <- mxConfig$defautUserName


  # check if the db does not hold any user
  # empty db means : first time we launch it.
  # first user is then a superuser
  emptyDb <- isTRUE(
    0 == mxDbGetQuery(
      sprintf(
        "SELECT count(id) FROM %s"
        , userTable
        )
      )
    )

  if(emptyDb){
    # first is superuser
    dat <- dataUserSuperuser
  }else{
    # .. then default
    dat <- dataUserDefault
  }

  stopifnot(length(dat)>0)

  #
  # Set username based on the user table sequence.
  #
  getCurId <- sprintf(
    "SELECT last_value as id FROM public.%s_id_seq"
    , userTable
    )
  nextId <- mxDbGetQuery(getCurId,onError=function(x){stop(x)})

  # quick check on what we get is what we expect
  if( nrow(nextId) > 0 && 'id' %in% names(nextId) ){
    nextId <- nextId$id + 1
  }else{
    stop("Error in mxDbCreateUser")
  }
  # create default name 
  userName <- sprintf(
    "%s_%s"
    , userNameDefault
    , nextId
    ) 


  newUser = list(
    username        = userName,
    email           = email,
    key             = randomString(),
    validated       = TRUE,
    hidden          = FALSE,
    date_validated  = timeStamp,
    date_last_visit = timeStamp,
    data            = mxToJsonForDb(dat)
    )


  mxDbAddRow(newUser,userTable)

}


mxToJsonForDb<- function(listInput){
  jsonlite::toJSON(listInput,auto_unbox=TRUE,simplifyVector = FALSE) %>%
  gsub("[\x09\x01-\x08\x0b\x0c\x0e-\x1f\x7f]"," ",.)%>%
    gsub("'","''",.)%>%
    as.character()
}





#' drop layer
#' layerName Layer (table + entry + views) to delete from db
#' @export
mxDbDropLayer <- function(layerName){
  qt <- sprintf("SELECT EXISTS( SELECT layer FROM mx_layers where layer='%1$s') as test",layerName)
  qv <- sprintf("SELECT EXISTS( SELECT layer FROM mx_views where layer='%1$s') as test",layerName)

  existsTable <- isTRUE(mxDbExistsTable(layerName))
  existsEntry <- isTRUE(mxDbGetQuery(qt)$test)
  existsViews <- isTRUE(mxDbGetQuery(qv)$test)

  if(existsTable){
    mxDbGetQuery(sprintf("DROP table %1$s",layerName))
  }
  if(existsEntry){ 
    mxDbGetQuery(sprintf("DELETE FROM mx_layers where layer='%1$s'",layerName))
  }

  if(existsViews){ 
    mxDbGetQuery(sprintf("DELETE FROM mx_views where layer='%1$s'",layerName))
  }

}

#' Helper to update a value in a data jsonb column in db and reactUser$data, given a path
#' @param reactUser  mapx reactives user values, containing 'data' item
#' @param value Value to update, at a given path
#' @param path Path to reach the value to update, in both db mx_users->data and reactUser$data$data
#' @export
  mxDbUpdateUserData <- function(reactUser,path,value){

      stopifnot(!noDataCheck(path))
      stopifnot(!noDataCheck(value))
      stopifnot(is.reactivevalues(reactUser))

      #
      # Check last value
      #
      valueOld <- mxGetListValue(
        li = reactUser$data$data,
        path = path
        ) 
      #
      # Check if this is different than the current country
      #
      if(
        !(
        identical(valueOld,value) ||
        identical(valueOld[names(value)],value)
      )
        ){
        #
        # Update
        #
      #  reactUser$data$data <- mxSetListValue(
          #li = reactUser$data$data,
          #path = path,
          #value = value
        #  )
        #
        # Save
        #
        mxDbUpdate(
          table=mxConfig$userTableName,
          idCol='id',
          id=reactUser$data$id,
          column='data',
          jsonPath = path,
          value = value
          )
      }
    }



