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


# get info about the host
mxConfig$os <- Sys.info()['sysname']
mxConfig$hostname <- Sys.info()['nodename']


if ( mxConfig$hostname == mxConfig$remoteHostname ) {
  mxConfig$protocolVt <- "http"
  mxConfig$protocolVtPublic <- "http"
  mxConfig$portVt <- 80
  mxConfig$portVtPublic <- 8080
  mxConfig$hostVt <- "localhost"
}else{
  mxConfig$protocolVt <- "http"
  mxConfig$protocolVtPublic <- "http"
  mxConfig$portVt <- 8080
  mxConfig$portVtPublic <- 8080
  mxConfig$hostVt <- "localhost"
} 



##########################################################################
#                                                                        #
# GLOBAL CONFIGURATION                                                   #
#                                                                        # 
##########################################################################
# set general parameters. Modify with caution :)

# default country code "ISO_3166-1_alpha-3"
mxConfig$defaultCountry <- "COD"
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
# No filter value
mxConfig$noFilter <- "[ ALL ]"
# map zoom
mxConfig$defaultZoom <- 9
# Default layer group name
mxConfig$defaultGroup <- "G1"
# column column used in postgis
mxConfig$defaultGeomCol <- "geom"
# cookies expiration in days
mxConfig$cookiesExpireDays <- 10 
# default email adress for sender
mxConfig$mapxBotEmail <- "bot@mapx.io"


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
      name = "afg",
      children = list(
        list(
          name = "aynak",
          children = list()
          )
        )
      ),
    list(
      name = "cod",
      children = list()
      )
    )
  )


mxRecSearch <- function(li,name="afg"){
  if(is.list(li) && length(li)>0){ 
    if("name" %in% names(li) && li$name==name){
      return(rapply(li,unlist))
    }else{
      if("children" %in% names(li)){
        lapply(li[['children']])
      }

      for(i in 1:length(li)){


        subLi = li[[li]]
        if("children" %in% names)
        print(i)
        browser()
        mxRecSearch(li[[i]],name)
      }
    }
  }else{
   return()
  }

}





# NOTE: each role is related to specific project : admin cod will not be able to change roles of user from afg
# only members of higher group levels can modify other members data
# tools : analysis tool
# read : read views and story maps (targeting is role)
#
#

mxConfig$roles <- list(
  "guest"=list(
    action = c("tools","read"),
    readers = c("")
    ),
  "user"=list(
    action=c("tools","read","create","update"),
    readers=c("self","editor","admin","superuser")
    ),
  "editor"=list(
    action=c("tools","read","create","update","edit"),
    readers=c("self","editor","admin","superuser","user")
    ),
  "admin"=list(
    action=c("tools","read","write","edit","manage"),
    target=c("temporary","self","editor","admin","superuser","public")
    ),
  "superuser"=list(
    action=c("read","write","edit","publish","upload","manage","config"),
    target=c("temporary","self","editor","admin","superuser","public") 
)
)


# roles
mxConfig$rolesVal <- list(
  "superuser" = 10000,
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

# set panel mode : available options
mxConfig$mapPanelModeAvailable <- c(
  "mx-mode-explorer",
  "mx-mode-config",
  "mx-mode-toolbox",
  "mx-mode-creator",
  "mx-mode-story-reader"
  )
# Name of the table containing layers meta data
mxConfig$layersTableName = "mx_layers"
# Name of the table containing the views data
mxConfig$viewsListTableName = "mx_views"
# Name of the table containing story maps
mxConfig$storyMapsTableName = "mx_story_maps"
# Prefix for archived 
mxConfig$prefixArchiveLayer = "mx_archived_layers"
mxConfig$prefixArchiveStory = "mx_archived_stories"
mxConfig$prefixArchiveViews = "mx_archived_views"

# Command to restart pgrestapi
# NOTE: touch "restart.txt" reactivate nodejs application launched by NGINX + passenger.
mxConfig$restartPgRestApi = "touch /home/vagrant/tools/pgrestapi/tmp/restart.txt"
# set palette colors for ui
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
  "MapBox Satellite" = "mapbox",
  "Nasa" = "nasa"
  )
# Set data classes
mxConfig$class = list(
  "Development" = "dev",
  "Energy"="nrg",
  "Environment" = "env",
  "Extractives" = "ext",
  "Stresses" = "str",
  "Social" = "soc",
  "Customs" = "cus",
  "Infrastructure" = "nfr",
  "Mes Aynak Area" = "maa",
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

#
#
## Set data subclasses
#mxConfig$subclass = list(
#  "dev" = list(
#    "Unemployment" = "unemployment",
#    "Poverty" = "poverty",
#    "Agriculture" = "agriculture"
#    ),
#  "env" = list(
#    "Climate change" = "climate",
#    "Biodiversity" = "biodiv",
#    "Water" = "water",
#    "Farming" = "farming",
#    "Population"="population",
#    "N/P/K cycles"="npkcycle",
#    "Land use" = "landuse",
#    "Nanotechnology" ="nanotech",
#    "Pollution"="pollution",
#    "Forest"="forest"
#    ),
#  "ext" = list(
#    "Mineral" = "mineral",
#    "Oil" = "oil",
#    "Forestry" = "forestry",
#    "Artisanal mines" = "mines_artisanal"
#    ),
#  "str" = list(
#    "Conflict" = "conflict" 
#    ),
# "trad" = list(
#    "Tribs" = "tribs" 
#    )
#  )
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
  #addVectorBase(layerId="basemap_back") %>%
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
  c(id=0,u="fred", l="570a90bfbf8c7eab5dc5d4e26832d5b1",k="570a90bfbf8c7eab5dc5d4e26832d5b1", r="superuser",e="moser.frederic@gmail.com"),
  c(id=1,u="pierre",l="84675f2baf7140037b8f5afe54eef841" ,k="84675f2baf7140037b8f5afe54eef841", r="superuser",e="mail@example.com"),
  c(id=2,u="david",l="172522ec1028ab781d9dfd17eaca4427",k="172522ec1028ab781d9dfd17eaca4427", r="user",e="mail@example.com"),
  c(id=3,u="dag",l="b4683fef34f6bb7234f2603699bd0ded", k="b4683fef34f6bb7234f2603699bd0ded", r="user",e="mail@example.com"),
  c(id=4,u="nicolas",l="deb97a759ee7b8ba42e02dddf2b412fe", k="deb97a759ee7b8ba42e02dddf2b412fe", r="admin",e="mail@example.com"),
  c(id=5,u="paulina",l="e16866458c9403fe9fb3df93bd4b3a41", k="e16866458c9403fe9fb3df93bd4b3a41", r="user",e="mail@example.com"),
  c(id=6,u="greg",l="ea26b0075d29530c636d6791bb5d73f4",k="ea26b0075d29530c636d6791bb5d73f4", r="user",e="mail@example.com"),
  c(id=7,u="guest",l="084e0343a0486ff05530df6c705c8bb4",k="084e0343a0486ff05530df6c705c8bb4", r="user",e="mail@example.com"),
  c(id=8,u="jjacques",l="6cb261a6203d1e441c5b2110a182701f",k="0e3b98b36a16e55b08ce156a02397506", r="user",e="mail@example.com"),
  c(id=9,u="sandra",l="f40a37048732da05928c3d374549c832",k="4925a6581bde894377a2827c9b94608c", r="user",e="mail@example.com"),
  c(id=10,u="mady",l="137f13f84ad65ab8772946f3eb1d3a65",k="57ba663c95d2e961727cf6ce004e5886", r="user",e="mail@example.com"),
  c(id=11,u="nik", l="f64609172efea86a5a6fbae12ab86d33",k="81dc9bdb52d04dc20036dbd8313ed055", r="superuser",e="nikos.alexandris@unepgrid.ch"),
  c(id=12,u="random", l="7ddf32e17a6ac5ce04a8ecbf782ca509",k="7ddf32e17a6ac5ce04a8ecbf782ca509", r="user",e="random@unepgrid.ch"),
  c(id=13,u="admin", l="21232f297a57a5a743894a0e4a801fc3",k="d25a67c94fa9f1f2775c956719b6b0f7", r="admin",e="admin@example.com")
  )

mxData$pwd <- as.data.frame(mxData$pwd,stringsAsFactors=F)
mxData$pwd$d <- Sys.time() # NOTE: In prod: use cookie "d" value as set in setCookie function. 



