


#
# restore libraries
#
packrat::restore()
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
# story map fucntion
#
source("helper/R/mxStoryMap.R")
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
# local configuration, not added to git repo
#
source("settings/config-local.R")


