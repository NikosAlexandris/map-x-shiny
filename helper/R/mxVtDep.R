leafletVectorTilesDependencies <- function() {
  ## in a function : call to htmlDependency in run time, not build time
  list(
    htmltools::htmlDependency(
      name = "mapbox-gl",
      version = "0.12.3",
      src = "www/src/mapboxGL/",
      stylesheet = "mapbox-gl.css",
      script = c(
        "mapbox-gl.js",
        "leaflet-mapbox-gl.js"
        )
      ),
    htmltools::htmlDependency(
      name = "leaflet-vector-tiles-lib",
      version = "0.1.7",
      src = "www/src/leafletMapboxVectorTiles/",
      #script = "Leaflet.MapboxVectorTile.min.js"
      script = "Leaflet.MapboxVectorTile.js"
      ),
    htmltools::htmlDependency(
      name = "leaflet-vector-tiles-binding",
      version = "0.0.1",
      src = "www/src/leafletVectorTilesBinding",
      script = "leaflet-vector-tiles-binding.js"
      )
    )
}


#' gl layer new
#' @export
glInit <- function(
  map,
  idGl,
  style,
  token
  ){
  map$dependencies <- c(map$dependencies, leafletVectorTilesDependencies())
  idMap <- map$id
  invokeMethod(map,getMapData(map),'glInit',idGl,idMap,style,token)
}

#' gl add source
#' @export
glAddSource <- function(map, idGl, idSource, style ){
  invokeMethod(map,getMapData(map),'glAddSource',idGl, idSource, style )
}

#' gl remove source
#' @export
glRemoveSource <- function(map, idGl, idSource ){
  invokeMethod(map,getMapData(map),'glRemoveSource',idGl,idSource)
}


#' gl add layer
#' @export
glAddLayer <- function(map, idGl, idBelowTo=NULL, style ) {
  invokeMethod(map,getMapData(map),'glAddLayer',idGl,idBelowTo, style)
}

#' gl remove layer
#' @export
glRemoveLayer <- function(map, idGl, idLayer ) {
  invokeMethod(map,getMapData(map),'glRemoveLayer',idGl,idLayer)
}

#' gl set paint property for a layer
#' @export
glSetPaintProperty <- function(map, idGl, idLayer, name, value) {
  invokeMethod(map,getMapData(map),'glSetPaintProperty',idGl,idLayer,name,value)
}

#' gl set filter for a layer
#' @export
glSetFilter <- function(map, idGl, idLayer, filter) {
  invokeMethod(map,getMapData(map),'glSetFilter',idGl,idLayer,filter)
}


#' Create url for pgrestapi source
#' @return url 
glMakeUrl <- function(
  protocol="http",
  host="localhost",
  port,
  table,
  fieldVariables,
  fieldGeom
  ){
 # layer <- paste0(table,"_",fieldGeom) 
  query <- sprintf("?fields=%s",paste(fieldVariables,collapse=",")) 

  url <- sprintf("%s://%s:%s/services/postgis/%s/%s/vector-tiles/{z}/{x}/{y}.pbf%s",
    protocol,
    host,
    port,
    table,
    fieldGeom,
    query)

 return(c(url,url))
}


#' Add vector tiles for a given PGRestAPI postgres endpoint.
#' @param map Leaflet map object
#' @param urlTemplate Url template for a given PGRestAPI endpoint.
#' @export
addVectorTiles <- function(
  map,
  userId="1",
  protocol="http",
  host="localhost",
  port=3030,
  layer=NULL,
  dataColumns=NULL,
  geomColumn="geom", # should be auto resolved by PGRestAPI
  idColumn="gid", # should be auto resolved by PGRrestAPI
  id = NULL,
  group="default",
  debug=FALSE,
  zIndex =100,
  onLoadFeedback=c('once','never','always')
) {
  onLoadFeedback <- match.arg(onLoadFeedback)
  #layer <- paste0(layer,"_",geomColumn)
  cols <- unique(c(idColumn,dataColumns))
  cols <- paste0(cols[!cols %in% geomColumn],collapse=",")
  cols <- gsub("\\s+","",cols)

  key <- mxDbGetQuery(sprintf("select key from mx_users where id=%1$s;",userId))$key
  stopifnot(!noDataCheck(key))

  


#  hex <- mxDbEncrypt(list(
      #user="1",
      #layer=layer,
      #variables=cols
      #))

  url <- sprintf('%1$s://%2$s:%3$s/tile/{z}/{x}/{y}.mvt?t=%4$s&l=%5$s&v=%6$s&u=%7$s',
   protocol,
   host,
   port,
   key,
   layer,
   cols,
   userId
  )
 
  map$dependencies <- c(map$dependencies, leafletVectorTilesDependencies())
  options = list(
    debug=debug,
    zIndex=zIndex,
    onLoadFeedback=onLoadFeedback
    )
  invokeMethod(map,getMapData(map),'addVectorTiles',url,layer,idColumn,id,group,options)
}


#' Remove vector tiles.
#' @param map Leaflet map object
#' @param group Group/id of the vector tiles layer
#' @export
setVectorTilesVisibility <- function(
  map,
  group="default",
  visible=TRUE
) {
  map$dependencies <- c(map$dependencies, leafletVectorTilesDependencies())
  invokeMethod(map,getMapData(map),'setVectorTilesVisibility',as.character(group))
}


#'@export
setZoom = function(map, zoom, options = list()) {
  view = list(zoom, options)
  dispatch(map,
    "setZoom",
    leaflet = {
      map$x$setZoom = view
      map$x$fitBounds = NULL
      map
    },
    leaflet_proxy = {
      leaflet:::invokeRemote(map, "setZoom", view)
      map
    }
    )
}
