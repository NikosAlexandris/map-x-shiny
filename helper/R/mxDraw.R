
#' Add leaflet draw tools
leafletDrawDependencies <- function() {
  list(
    htmltools::htmlDependency(
      "leaflet-draw",
      "0.2.3", 
      src =normalizePath("www/src/leafletDraw"),
      script = "leaflet.draw.js",
      stylesheet = "leaflet.draw.css"
      ),
    htmltools::htmlDependency(
      "leaflet-draw-plugin",
      "0.0.1",
      src=normalizePath("www/src/leafletDraw"),
      script = "bindings.js"
      )
    )
}

# leaflet draw function
addDraw <- function(
  map
  , options
) {
  map$dependencies <- c(map$dependencies, leafletDrawDependencies())
  invokeMethod(
    map
    , getMapData(map)
    , 'toggleDraw'
    , options
  )
}

#' @export
removeDraw <- function( map ){
  invokeMethod(
    map
    , getMapData(map)
    , 'removeDraw'
  )
}


