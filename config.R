# Set shiny options
options(shiny.maxRequestSize=30*1024^2)
# map-x configuration list (hold parameters)
mxConfig <- list()
# map-x data set list (hold data set imported from text or elsewhere)
mxData <- list()


#
# Config
#

mxConfig$defaultCountry = "COD"
# no data string
mxConfig$noData = "[ NO DATA ]"
# Defaut value string
mxConfig$noVariable = "[ DEFAULT ]"
# No layer string
mxConfig$noLayer = "[ NO LAYER ]"
# No filter value
mxConfig$noFilter = "[ ALL ]"
# map zoom
mxConfig$defaultZoom = 9
# Default layer group name
mxConfig$defaultGroup = "G1"
# column column used in postgis
mxConfig$defaultGeomCol = "geom"
# In this case : Darwin = devel environment; linux = production environment
mxConfig$os<-Sys.info()['sysname']
# port depending on which plateform map-x shiny is launched
switch(
  mxConfig$os,
  'Darwin'={
    mxConfig$portVt <- 8080
    mxConfig$portVtPublic <- 8080
    mxConfig$hostVt <- "localhost"
    print("map-x launched on MAC OX X")
  },
  "Linux"={
    mxConfig$portVt <- 80
    mxConfig$portVtPublic <- 8080
    mxConfig$hostVt <- "localhost"
    print("map-x launched on LINUX")
  } 
  )
# roles
mxConfig$rolesVal <- list(
  "superuser" = 1000,
  "admin" = 1000,
  "user" = 100,
  "visitor" = 0
  )
# input file formating
# https://en.wikipedia.org/wiki/GIS_file_formats
# http://www.w3schools.com/tags/att_input_accept.asp
mxConfig$inputDataExt <-list(
  "vector"=list(
    "Shapefile"=c(".shp",".shx",".dbf",".prj"),
    "GeoJSON"=c(".geojson",".json")
    ),
  "raster"=list(
    "GTiff"=c(".tif",".tiff",".geotiff")
    )
  )
# structured list data format
mxConfig$inputDataFileFormat <- list(
  "Shapefile" = list(
    name = "shapefile",
    type = "vector",
    fileExt = mxConfig$inputDataExt$vector$Shapefile,
    multiple = TRUE
    ),
  "GeoJSON" = list(
    name = "geojson",
    type = "vector",
    fileExt = mxConfig$inputDataExt$vector$GeoJSON,
    multiple = FALSE
    )
  )
# Name of the table containing the views data
mxConfig$viewsListTableName = "mx_views"
# Command to restart pgrestapi
# NOTE: touch "restart.txt" reactivate nodejs application launched by NGINX + passenger.
mxConfig$restartPgRestApi = "touch /home/vagrant/tools/PGRestAPI/tmp/restart.txt"
# set palette colors
mxConfig$colorPalettes <- mxCreatePaletteList(RColorBrewer::brewer.pal.info)
# country data
# http://unstats.un.org/unsd/methods/m49/m49alpha.htm
# http://eiti.org/countries/reports/compare/download/xls
countryEitiTable <- import('data/countriesEiti.ods')
# get country center from existing table
mxConfig$countryCenter <- mxEitiGetCountryCenter(countryEitiTable)
# get country list formated for selectize input
mxConfig$countryListChoices <- mxEitiGetCountrySelectizeList(countryEitiTable)
# set wdi infos
mxConfig$wdiIndicators <- mxGetWdiIndicators()
# list of tile provider
mxConfig$tileProviders = list(
  "Default" = mxConfig$noLayer,
  "Simple I" = "CartoDB.PositronNoLabels",
  "Simple II" = "Hydda.Base",
  "Dark" = "CartoDB.DarkMatterNoLabels",
  "HillShade" = "Acetate.hillshading",
  "Shaded relief" = "HERE.satelliteDay",
  "Terrain" ="Esri.WorldTerrain",
  "Acetate" = "Acetate.terrain",
  "Satellite I" = "HERE.satelliteDay",
  "Satellite II" = "MapQuestOpen.Aerial",
  "MapBox Satellite" = "mapbox"
  )
# Set data classes
mxConfig$class = list(
  "Development" = "dev",
  "Environment" = "env",
  "Extractives" = "ext",
  "Stresses" = "str"
  )
# Set data subclasses
mxConfig$subclass = list(
  "dev" = list(
    "Unemployment" = "unemployment",
    "Poverty" = "poverty",
    "Agriculture" = "agriculture"
    ),
  "env" = list(
    "Forest cover" = "forest",
    "Deforestation" = "deforest",
    "Biodiversity" = "biodiversity"
    ),
  "ext" = list(
    "Mineral" = "mineral",
    "Oil" = "oil",
    "Forestry" = "forestry",
    "Artisanal mines" = "mines_artisanal"
    ),
  "str" = list(
    "Conflict" = "conflict" 
    )
  )
# Set default years avaiable for date inputs
mxConfig$currentTime <- Sys.time()
mxConfig$currentYear <- as.integer(format(mxConfig$currentTime,"%Y"))
mxConfig$yearsAvailable <- seq(mxConfig$currentYear,mxConfig$currentYear+50)
# Set default date for date picker
mxConfig$minDate <- paste0(mxConfig$currentYear-50,"-01-01")
mxConfig$maxDate <- paste0(mxConfig$currentYear+50,"-01-01")


#
# DATA
#


# md5 hashed pwd (for testing only)
# u = user
# l = login
# k = key
# e = email
# r = role
# d = last date login
# a = actually logged
# c = country allowed (all,pending,complete or single iso3)
mxData$pwd <- rbind(
  c(id=0,u="fred", l="570a90bfbf8c7eab5dc5d4e26832d5b1",k="570a90bfbf8c7eab5dc5d4e26832d5b1", r="superuser",e="mail@example.com"),
  c(id=1,u="pierre",l="84675f2baf7140037b8f5afe54eef841" ,k="84675f2baf7140037b8f5afe54eef841", r="superuser",e="mail@example.com"),
  c(id=2,u="david",l="172522ec1028ab781d9dfd17eaca4427",k="172522ec1028ab781d9dfd17eaca4427", r="user",e="mail@example.com"),
  c(id=3,u="dag",l="b4683fef34f6bb7234f2603699bd0ded", k="b4683fef34f6bb7234f2603699bd0ded", r="user",e="mail@example.com"),
  c(id=4,u="nicolas",l="deb97a759ee7b8ba42e02dddf2b412fe", k="deb97a759ee7b8ba42e02dddf2b412fe", r="admin",e="mail@example.com"),
  c(id=5,u="paulina",l="e16866458c9403fe9fb3df93bd4b3a41", k="e16866458c9403fe9fb3df93bd4b3a41", r="user",e="mail@example.com"),
  c(id=6,u="greg",l="ea26b0075d29530c636d6791bb5d73f4",k="ea26b0075d29530c636d6791bb5d73f4", r="user",e="mail@example.com"),
  c(id=7,u="guest",l="084e0343a0486ff05530df6c705c8bb4",k="084e0343a0486ff05530df6c705c8bb4", r="user",e="mail@example.com")
  )
mxData$pwd <- as.data.frame(mxData$pwd,stringsAsFactors=F)
mxData$pwd$d <- Sys.time() # NOTE: In prod: use cookie "d" value as set in setCookie function. 




mxData$countryStory <- fromJSON('data/countriesEitiStory.json')
mxData$rgi_score_2013 <- na.omit(import('data/rgi_2013-compscores.csv'))
mxData$rgi_score_2013$iso3 <- countrycode(mxData$rgi_score_2013$Country,'country.name','iso3c')







