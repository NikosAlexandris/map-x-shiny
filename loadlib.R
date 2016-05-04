#                             
#  _ __ ___   __ _ _ __   __  __
# | '_ ` _ \ / _` | '_ \  \ \/ /
# | | | | | | (_| | |_) |  >  < 
# |_| |_| |_|\__,_| .__/  /_/\_\
#                 | |           
#                 |_|           
# map-x dependencies.
# NOTE: everything is installed via packrat::install_github()

# essentials
library(shiny)
library(memoise)
library(leaflet)
library(jsonlite)
library(WDI)
library(countrycode)
library(devtools)

# upload and manage spatial data 
library(RPostgreSQL)
library(rio)
library(gdalUtils) 
library(rgdal)

# Graphs 
library(dygraphs)
library(xts)


# data transfer
library(base64enc)
library(digest)
# story map
library(knitr)
