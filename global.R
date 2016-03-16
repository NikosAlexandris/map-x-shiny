
#
# R libraries (managed using packrat !)
#
source("loadlib.R")
#
# map-x general functions 
#
source("helper/R/mxMisc.R")
#
# map-x ui functions 
#
source("helper/R/mxUi.R")
#
# leaflet R plugin : draw
#
source("helper/R/mxDraw.R")
#
# add vector tiles in "mapbox gl" or "leaflet mapbox vector tiles"
#
source("helper/R/mxVtDep.R")
#
# helper to get info on available pgrestapi layers
#
source("helper/R/mxPgRest.R")
#
# Helper for postgis request
#
source("helper/R/mxDb.R")
#
# handson table functions
#
source('helper/R/mxHandson.R')
#
# general configuration, site independant.
#
source("settings/config-global.R")
#
# configuration specific to the host on wich map-x is launched
#
source("settings/config-local.R")
