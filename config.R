


options(shiny.maxRequestSize=30*1024^2)

mxConfig <- list()
mxData <- list()

mxConfig$defaultZoom = 9


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
mxConfig$noLayer = "[NO LAYER]"
mxConfig$restartPgRestApi = "pm2 restart app"

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
      #paste0("<li><a href=?country=",countryList$pending,"#sectionCountry>",names(countryList$pending),"</a></li>",collapse=""),
      paste0("<li><a href=?country=",countryList$pending,"#>",names(countryList$pending),"</a></li>",collapse=""),
      paste0("<li class='dropdown-header'>Potential</li>"),
      #paste0("<li><a href=?country=",countryList$potential,"#sectionCountry>",names(countryList$potential),"</a></li>",collapse="")
      paste0("<li><a href=?country=",countryList$potential,"#>",names(countryList$potential),"</a></li>",collapse="")
      )
  )


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
  'dev' = list(
    'Unemployment'='unemployment',
    'Poverty' ='poverty'
    ),
  'env' = list(
    'Forest cover'='forest',
    'Deforestation'="deforest",
    'Biodiversity'='biodiversity'
    ),
  'ext' = list(
    'Mineral'='mineral',
    "Oil"='oil',
    "Forestry"="forestry",
    "Artisanal mines"="mines_artisanal"
    ),
  'str'=list(
    "Conflict"="conflict" 
    )
  )

mxConfig$yearsAvailable = format(Sys.time(),"%Y") : 1950




#
# SET WDI INFOS
#


mxConfig$wdiIndicators <- WDIsearch()[,'indicator']
names(mxConfig$wdiIndicators) <- WDIsearch()[,'name']
mxData$rgi_score_2013 <- na.omit(import('data/rgi_2013-compscores.csv'))
mxData$rgi_score_2013$iso3 <- countrycode(mxData$rgi_score_2013$Country,'country.name','iso3c')

names(mxData$rgi_score_2013)

#
