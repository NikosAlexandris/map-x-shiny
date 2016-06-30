#                             
#  _ __ ___   __ _ _ __   __  __
# | '_ ` _ \ / _` | '_ \  \ \/ /
# | | | | | | (_| | |_) |  >  < 
# |_| |_| |_|\__,_| .__/  /_/\_\
#                 | |           
#                 |_|           
# configuration global.


# Set shiny options
options(shiny.maxRequestSize=300*1024^2)
options(stringsAsFactors=FALSE)
# map-x configuration list (hold parameters)
mxConfig <- list()
# map-x data set list (hold data set imported from text or elsewhere)
mxData <- list()


# set debugger
options(
 shiny.reactlog=FALSE,
 shiny.trace=FALSE
 )


##########################################################################
#                                                                        #
# LOCAL CONFIGURATION                                                    #
#                                                                        # 
##########################################################################

# those settings should be modified in /settings/config-local.R 


mxConfig$remoteHostname = "map-x-full"


mxConfig$remoteInfo <- list(
  host="127.0.0.1",
  user="vagrant",
  port=2222
  )
mxConfig$dbInfo <- list(
  host='127.0.0.1',
  dbname='mapx',
  port='5432',
  user='mapxw',
  password='"<put_your_postgres_pwd_here>"'
  )
mxConfig$key <- digest("<put_a_strong_key_here>")

mxConfig$dbMaxConnections = 5;


# get info about the host
mxConfig$os <- Sys.info()['sysname']
mxConfig$hostname <- Sys.info()['nodename']



##########################################################################
#                                                                        #
# GLOBAL CONFIGURATION                                                   #
#                                                                        # 
##########################################################################
# set general parameters. Modify with caution :)


# default language code "ISO 639-2"
mxConfig$defaultLanguage <- "eng"
# available languages
mxConfig$languageList <- c("eng","fre")
# no data string
mxConfig$noData <- "[ NO DATA ]"
# Defaut value string
mxConfig$noVariable <- "[ DEFAULT ]"
# No layer string
mxConfig$noLayer <- "[ NO LAYER ]"
# No title
mxConfig$noTitle <- "[ NO TITLE ]"
# Select 
mxConfig$noSelect <- "[ SELECT ]"
# No filter value
mxConfig$noFilter <- "[ ALL ]"

mxConfig$defaultNoDatas <- c(
  mxConfig$noData,
  mxConfig$noVariable,
  mxConfig$noLayer,
  mxConfig$noTitle,
  mxConfig$noSelect,
  mxConfig$noFilter
  )


# map zoom
mxConfig$defaultZoom <- 9
# Default layer group name
mxConfig$defaultGroup <- "G1"
# column column used in postgis
mxConfig$defaultGeomCol <- "geom"
# cookies expiration in days
mxConfig$cookiesExpireDays <- 30 
# default email adress for sender
mxConfig$mapxBotEmail <- "bot@mapx.io"
mxConfig$mapxGuestEmail = "guest@mapx.io"
# default username
mxConfig$defautUserName <- "user"


# default data for new users
mxConfig$defaultDataPublic <- list(
  user=list(
    preferences=list(
      language = mxConfig$defaultLanguage
      ),
    cache = list (
      last_project = mxConfig$defaultCountry 
      )
    ),
  admin=list(
    roles =  list(
      list(
        project =  "world",
        role = "public"
        )
      )
    )
  )

# default data for new  superuser if database is empty
mxConfig$defaultDataSuperuser <- list(
  user=list(
    preferences=list(
      language = mxConfig$defaultLanguage,
      last_project = mxConfig$defaultCountry
      ),
    cache = list (
      last_project = mxConfig$defaultCountry 
      )
    ),
  admin=list(
    roles =  list(
      list(
        project = "world",
        role = "superuser"
        )
      )
    )
  )
# set default data path
mxConfig$dataPathLastStory <- c("data","user","cache","last_story")


# style
  mxConfig$defaultStyle <- list(
    title = character(0),
    colors = character(0),
    paletteFun = function(){},
    values =character(0),
    variable=character(0),
    layer=character(0),
    opacity=0.8,
    size=20,
    group=mxConfig$defaultGroup,
    bounds=numeric(0),
    mxDateMin=numeric(0),
    mxDateMax=numeric(0),
    variableUnit=character(0)
    )




# groups definition




#mxConfig$modules <- list(
  #"all",
  #"map",
  #"tool",
  #"country",
  #"story",
  #"upload",
  #"view"
  #)


# project tree is valid agains schema in mxConfig$schemas$projectTree 
mxConfig$projectTree  <- list(
  name = "world",
  children = list(
    list(
      name = "AFG",
      children = list(
        list(
          name = "aynak",
          children = list()
          )
        )
      ),
    list(
      name = "COD",
      children=list()
      )
    )
  )


# note : could be searched with function
#mxRecursiveSearch(mxConfig$roles,"role","==","admin")
# role definition : 
# each user has a role stored in the database : public, user, editor, admin or superuser.
# each roles is described in the following list.
# access : which parts of the application the user can access ?
# read : which target groups the user can read ?
# edit : which target groups the user can edit ?
# profile : which groups the user can modify settings ?
# admin : which group the user can modify roles ?
mxConfig$roles <- list(
  list(
    role="public",
    level=4,
    desc = list(
      access = c("map","country"),
      read = c("public"),
      publish = c(),
      edit = c(),
      profile = c(),
      admin = c()
      )
    ),
  list(
    role="user",
    level=3,
    desc=list(
      access = c("map","storymap","country","profile","view_creator","storymap_creator","tools"),
      read = c("self","user","public"),
      publish = c("self","editor"),
      edit = c("self"),
      profile = c("self"),
      admin = c()
      )
    ),
  list(
    role="editor",
    level=2,
    desc = list(
      access = c("map","storymap","country","profile","view_creator","storymap_creator","tools"),
      read = c("self","user","public","editor"),
      publish = c("self","user","public","editor"),
      edit = c("self","user"),
      profile = c("self"),
      admin = c()
      )
    ),
  list(
    role="admin",
    level=1,
    desc = list(
      access = c("map","storymap","country","profile","admin","view_creator","storymap_creator","tools","data_upload"),
      read = c("self","user","public","editor","admin"),
      publish = c("self","user","public","editor","admin"),
      edit = c("self","user","editor","admin"),
      profile = c("self"),
      admin = c("public","user","editor")
      )
    ),
  list(
    role="superuser",
    level=0,
    desc = list(
      access = c("map","storymap","country","profile","admin","config","view_creator","storymap_creator","tools","data_upload"),
      read = c("self","public","user","editor","admin","superuser"),
      publish = c("self","user","public","editor","admin","superuser"),
      edit = c("self","user","editor","admin","superuser"),
      profile = c("self","public","user","editor","admin","superuser"),
      admin = c("public","user","editor","admin","superuser")
      )
    )
  )




## roles
#mxConfig$rolesVal <- list(
  #"superuser" = 10000,
  #"admin" = 1000,
  #"user" = 100,
  #"visitor" = 0
  #)
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

# set panel mode : available options
mxConfig$mapPanelModeAvailable <- c(
  "mx-mode-explorer",
  "mx-mode-config",
  "mx-mode-toolbox",
  "mx-mode-creator",
  "mx-mode-story-reader"
  )


# name of user table
mxConfig$userTableName = "mx_users" 

# Name of the table containing layers meta data
mxConfig$layersTableName = "mx_layers"
# default cookie name
mxConfig$defaultCookieName = "mx_data"
# Name of the table containing the views data
mxConfig$viewsListTableName = "mx_views"
# Name of the table containing story maps
mxConfig$storyMapsTableName = "mx_story_maps"
# Prefix for archived 
mxConfig$prefixArchiveLayer = "mx_archived_layers"
mxConfig$prefixArchiveStory = "mx_archived_stories"
mxConfig$prefixArchiveViews = "mx_archived_views"

# set palette colors for ui
mxConfig$colorPalettes <- mxCreatePaletteList()
# country data
# http://unstats.un.org/unsd/methods/m49/m49alpha.htm
# http://eiti.org/countries/reports/compare/download/xls
mxConfig$countryEitiTable <- import('data/countriesEiti.ods')
# get country center from existing table
mxConfig$countryCenter <- mxEitiGetCountryCenter(mxConfig$countryEitiTable)
# get country list formated for selectize input
mxConfig$countryListChoices <- mxEitiGetCountrySelectizeList(mxConfig$countryEitiTable)
# default country code "ISO_3166-1_alpha-3"
mxConfig$defaultCountry <- "COD"
# default countries for users
mxConfig$countryUser <- c("AFG","COD","SLE","NGA")
# default countries for others
mxConfig$countryAdmin <- mxConfig$countryEitiTable$code_iso_3 
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
  "MapBox Satellite" = "mapbox",
  "Nasa" = "nasa"
  )


# config wms source
mxConfig$wmsSources = list(
  "forestCover"="http://50.18.182.188:6080/arcgis/services/ForestCover_lossyear/ImageServer/WMSServer",
  "columbia.edu"="http://sedac.ciesin.columbia.edu/geoserver/wms",
  "preview.grid.unep.ch"="http://preview.grid.unep.ch:8080/geoserver/wms",
  "sampleserver6.arcgisonline.com"="http://sampleserver6.arcgisonline.com/arcgis/services/911CallsHotspot/MapServer/WMSServer",
  "nowcoast.noaa.gov"="http://nowcoast.noaa.gov/arcgis/services/nowcoast/analysis_meteohydro_sfc_qpe_time/MapServer/WmsServer"
  )



# Set data classes
mxConfig$class = list(
  "Pilot sites" = "maa",
  "Extractives" = "ext",
  "Development" = "dev",
  "Social" = "soc",
  "Environment" = "env",
  "Stresses" = "str",
  "Energy"="nrg",
  "Customs" = "cus",
  "Infrastructure" = "nfr",
  "Boundaries" = "bnd"
  )

# defaut text for text area in meta data editor
mxConfig$bibDefault = "
title = Title
author = Authors
organization = Map-x
address = Geneva
year = 2016
url = http://
"

# Set default years avaiable for date inputs
mxConfig$currentTime <- Sys.time()
mxConfig$currentYear <- as.integer(format(mxConfig$currentTime,"%Y"))
mxConfig$yearsAvailable <- seq(mxConfig$currentYear,mxConfig$currentYear-30)
# Set default date for date picker
mxConfig$minDate <- paste0(mxConfig$currentYear-50,"-01-01")
mxConfig$maxDate <- paste0(mxConfig$currentYear+50,"-01-01")


#
# DATA
#



mxData$countryStory <- fromJSON('data/countriesEitiStory.json')
mxData$rgi_score_2013 <- na.omit(import('data/rgi_2013-compscores.csv'))
mxData$rgi_score_2013$iso3 <- countrycode(mxData$rgi_score_2013$Country,'country.name','iso3c')


#mxConfig$mapboxToken = "pk.eyJ1IjoiaGVsc2lua2kiLCJhIjoiMjgzYWM4NTE0YzQyZGExMTgzYTJmNGIxYmEwYTQwY2QifQ.dtq8cyvJFrJSUmSPtB6Q7A"
mxConfig$mapboxToken = "pk.eyJ1IjoidW5lcGdyaWQiLCJhIjoiY2lrd293Z3RhMDAzNHd4bTR4YjE4MHM0byJ9.9c-Yt3p0aKFSO2tX6CR26Q"
#mxConfig$mapboxStyle = "mapbox://styles/helsinki/cik9kvy2d0023b6m40iq3dhwe"  
mxConfig$mapboxStyle = "mapbox://styles/unepgrid/cikwoxzjr00fob0lxslqnu3r9"

# Default base layer for testing
mxConfig$baseLayerByCountry = function(iso3="AFG",group="main",center=c(lng=0,lat=0,zoom=5)){
   leaflet() %>%
  clearGroup(group) %>%
  addGlLayer() %>%
 addVectorCountries(
          url            = mxConfig$hostVt,
          port           = mxConfig$portVtPublic,
          table          = "mx_country_un",
          iso3column     = "iso3code",
          iso3select     = iso3,
          geomColumn     = "geom",
          idColumn       = "gid",
          id             = group
          ) %>% 
  setView(center$lng,center$lat,center$zoom)
}

# login time in minutes
mxConfig$loginTimerMinutes <- 20
