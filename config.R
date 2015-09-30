options(shiny.maxRequestSize=30*1024^2)

mxConfig <- list()
mxData <- list()

mxConfig$defaultZoom = 9


#
# SET OS INFO
#

# set location specific variable.
# In this case : Darwin = devel environment; linux = production environment
mxConfig$os<-Sys.info()['sysname']

switch(mxConfig$os,
  'Darwin'={
    mxConfig$portVt <- 8080
    mxConfig$hostVt <- "localhost"
    print("map-x launched on MAC OX X")

  },
  "Linux"={
    mxConfig$portVt <- 3030
    mxConfig$hostVt <- "calc.grid.unep.ch"
    print("map-x launched on LINUX")
  } 
  )


mxConfig$rolesVal <- list(
  "superuser" = 1000,
  "admin" = 1000,
  "user" = 100,
  "visitor" = 0
  )

mxConfig$defaultGroup = "G1"
mxConfig$defaultGeomCol = "geom"

#
# INPUT FILE FORMATING
#

mxConfig$inputDataExt <-list(
  "vector"=list(
    "Shapefile"=c(".shp",".shx",".dbf",".prj"),
    "GeoJSON"=c(".geojson",".json")
    ),
  "raster"=list(
    "GTiff"=c(".tif",".tiff",".geotiff")
    )
  )


# https://en.wikipedia.org/wiki/GIS_file_formats
# http://www.w3schools.com/tags/att_input_accept.asp
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



mxConfig$viewsListTableName = "mx_views"



mxConfig$noData = "[NO DATA]"
mxConfig$noVariable = "[DEFAULT]"
mxConfig$noLayer = "[NO LAYER]"
mxConfig$restartPgRestApi = "pm2 restart 'pgrestapi'"
#mxConfig$restartPgRestApi = "pathToTmp=/home/vagrant/tools/PGRestAPI/tmp; mkdir -p $pathToTmp touch $pathToTmp/restart.txt"

#
# set available palettes
#

pals = RColorBrewer::brewer.pal.info
palsName = paste(row.names(pals)," (n=",pals$maxcolors,"; cat=",pals$category,"; ", ifelse(pals$colorblind,"cb=ok","cb=warning"),")",sep="")

mxConfig$colorPalettes = row.names(pals)
names(mxConfig$colorPalettes) = palsName

#
#palDiv = pals[pals$category=="div",]
#palSeq = pals[pals$category=="seq",]
#palQual = pals[pals$category=="qual",]
#
#palDivName = paste(row.names(palDiv)," (n=",palDiv$maxcolors,"; ",ifelse(palDiv$colorblind,"colorblind=ok","colorblind=warning"),")",sep="")
#palSeqName = paste(row.names(palSeq)," (n=",palSeq$maxcolors,"; ",ifelse(palSeq$colorblind,"colorblind=ok","colorblind=warning"),")",sep="")
#palQualName = paste(row.names(palQual)," (n=",palQual$maxcolors,"; ",ifelse(palQual$colorblind,"colorblind=ok","colorblind=warning"),")",sep="")
#
#mxConfig$colorsPaletteDivergent = row.names(palDiv)
#names(mxConfig$colorsPaletteDivergent) = palDivName
#
#mxConfig$colorsPaletteSequential = row.names(palSeq)
#names(mxConfig$colorsPaletteSequential) = palSeqName
#
#mxConfig$colorsPaletteQualitative = row.names(palQual)
#names(mxConfig$colorsPaletteQualitative) = palQualName
#


#
# country data
#


# http://unstats.un.org/unsd/methods/m49/m49alpha.htm
# http://eiti.org/countries/reports/compare/download/xls

countryEitiTable <- import('data/countriesEiti.ods')


#
# Country default coordinates and zoom
#

mxConfig$countryCenter <- lapply(
  countryEitiTable$code_iso_3,function(x){
    res=countryEitiTable[countryEitiTable$code_iso_3==x,c('lat','lng','zoom')]
    res
  }
  )
names(mxConfig$countryCenter) <- countryEitiTable$code_iso_3





countryEitiTable$map_x_pending <- as.logical(countryEitiTable$map_x_pending)
#countryEitiTable$name_ui <- paste("[",countryEitiTable$code_iso_3,"]",countryEitiTable$name_un,'(',countryEitiTable$name_official,')')
countryEitiTable$name_ui <- paste(countryEitiTable$name_un,'(',countryEitiTable$name_official,')')
countryList <- list(
  "completed" = NULL,
  "pending"= as.list(countryEitiTable[countryEitiTable$map_x_pending,"code_iso_3"])  ,
  "potential"= as.list(countryEitiTable[!countryEitiTable$map_x_pending,"code_iso_3"])
  )
names(countryList$pending) = countryEitiTable[countryEitiTable$map_x_pending,"name_ui"]
names(countryList$potential) = countryEitiTable[!countryEitiTable$map_x_pending,"name_ui"]

mxConfig$countryListChoices = countryList


mxConfig$countryListHtml  = HTML(
  paste0(
      paste0("<li class='dropdown-header'>Pending</li>"),
      paste0("<li><a href=?country=",countryList$pending,"#>",names(countryList$pending),"</a></li>",collapse=""),
      paste0("<li class='dropdown-header'>Potential</li>"),
      paste0("<li><a href=?country=",countryList$potential,"#>",names(countryList$potential),"</a></li>",collapse="")
      )
  )

#
#output$countryDropDown  = renderUI(HTML(
#  paste0(
#      paste0("<li class='dropdown-header'>Pending</li>"),
#      paste0("<li><a href=?country=",countryList$pending,"#>",names(countryList$pending),"</a></li>",collapse=""),
#      paste0("<li class='dropdown-header'>Potential</li>"),
#      paste0("<li><a href=?country=",countryList$potential,"#>",names(countryList$potential),"</a></li>",collapse="")
#      )
#  ))
#


mxData$countryInfo <- fromJSON('data/countriesEitiStory.json')


#
# list of tile provider
#


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



#
# SET DATA CLASSES
#


mxConfig$class = list(
  "Development" = "dev",
  "Environment" = "env",
  "Extractives" = "ext",
  "Stresses" = "str"
  )

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

mxConfig$yearsAvailable = format(Sys.time(),"%Y") : 1950


#
# Set default date for date picker
#

mxConfig$minDate <- "1970-01-01"
mxConfig$maxDate <- "2200-01-01"



#
# SET WDI INFOS
#


mxConfig$wdiIndicators <- WDIsearch()[,'indicator']
names(mxConfig$wdiIndicators) <- WDIsearch()[,'name']
mxData$rgi_score_2013 <- na.omit(import('data/rgi_2013-compscores.csv'))
mxData$rgi_score_2013$iso3 <- countrycode(mxData$rgi_score_2013$Country,'country.name','iso3c')

names(mxData$rgi_score_2013)

#


#
# BASE LAYER
#


mxConfig$baseLayerByCountry = function(iso3="AFG",group="main",center=c(lng=0,lat=0,zoom=5)){
  switch(iso3,
    "COD"={
      leaflet() %>%
      clearGroup(group) %>%
      addTiles(
        paste0("http://",mxConfig$hostVt,":3030/services/tiles/cod_base_layer_0_6/{z}/{x}/{y}.png"),
        group=group,
        options=list(
          "zIndex"=0,
          "minZoom"=0,
          "maxZoom"=6)
        ) %>%  
      addTiles(
       paste0("http://",mxConfig$hostVt,":3030/services/tiles/cod_base_layer_7_10/{z}/{x}/{y}.png"),
        group=group,
        options=list(
          "zIndex"=0,
          "minZoom"=7,
          "maxZoom"=10)
        ) %>%
      setView(center$lng,center$lat,center$zoom)
    },
    "AFG"={
      leaflet() %>%
      clearGroup(group) %>%
      addTiles(
        paste0("http://",mxConfig$hostVt,":3030/services/tiles/afg_base_layer/{z}/{x}/{y}.png"),
        group=group,
        options=list(
          "zIndex"=0
          )
        )%>% setView(center$lng,center$lat,center$zoom)
    } 
    )
}


#
# LABEL LAYER
#


mxConfig$labelLayerByCountry=function(iso3,group,proxyMap){
  switch(iso3,
    "COD"={
      proxyMap %>%
      clearGroup(group) %>%
      addTiles(
        paste0("http://",mxConfig$hostVt,":3030/services/tiles/cod_labels_0_6/{z}/{x}/{y}.png"),
        group=group,
        options=list(
          "zIndex"=30,
          "minZoom"=0,
          "maxZoom"=6)
        ) %>%  addTiles(
        paste0("http://",mxConfig$hostVt,":3030/services/tiles/cod_labels_7_10/{z}/{x}/{y}.png;"),
        group=group,
        options=list(
          "zIndex"=30,
          "minZoom"=7,
          "maxZoom"=10)
        )
    },
    "AFG"={
      proxyMap %>%
      clearGroup(group) %>%
      addTiles(
        paste0("http://",mxConfig$hostVt,":3030/services/tiles/afg_labels/{z}/{x}/{y}.png"),
        group=group,
        options=list(
          zIndex=30
          )
        )
    }
    )
}



#
#  Language
#

mxConfig$languageText <- NULL


mxConfig$languageTooltip <- list(
  #
  # NAVIGATION BAR
  #
  "navBarHome"=list(
    "en"="Home screen",
    "fr"="Écran de départ"
    ),
  "navBarProfil"=list(
    "en"="Authentication and profil",
    "fr"="Authentification et profil "
    ),
  "navBarCountry"=list(
    "en"="Country selection and statistics",
    "fr"="Sélection du pays et statistiques"
    ),
  "navBarMap"=list(
    "en"="Spatial analysis and web mapping",
    "fr"="Analyse spatiale et cartographie interactive"
    ),
  "navBarAbout"=list(
    "en"="About",
    "fr"="À propos"
    ),
  "navBarAdmin"=list(
    "en"="Admin panel",
    "fr"="Panneau d'administration"
    ),
  "navBarContact"=list(
    "en"="Contact map-x team",
    "fr"="Contacter l'équipe map-x"
    ),
  #
  # MAP LEFT PANEL BUTTONS
  #

  "mapLeftLock"=list(
    "en"="Avoid scroll on left panel",
    "fr"="Eviter le scroll sur le paneau de gauche"
    ),
  "mapLeftHide"=list(
    "en"="Hide pannel",
    "fr"="Masquer le paneau"
    ),
  "mapLeftExplorer"=list(
    "en"="Display the map views explorer",
    "fr"="Afficher l'explorateur de vues"
    ),
  "mapLeftAdd"=list(
    "en"="Add data and configure views",
    "fr"="Ajouter des données et configurer les vues"
    ),
  "mapLeftInfo"=list(
    "en"="Display info panel",
    "fr"="Afficher le panneau d'information"
    ),
  "mapLeftConfig"=list(
    "en"="Display general configuration panel",
    "fr"="Afficher le panneau de configuration général "
    ),
  "mapLeftAnalysis"=list(
      "en"="Display spatial analysis panel",
      "fr"="Afficher le paneau d'analyse spatiale"
      )
  )  



mxConfig$languageChoice = "fr"
