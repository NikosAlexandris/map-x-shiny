


options(shiny.maxRequestSize=30*1024^2)

mxConfig <- list()
mxData <- list()



# http://unstats.un.org/unsd/methods/m49/m49alpha.htm
# http://eiti.org/countries/reports/compare/download/xls
eitiCountry <- import('data/countriesEiti.ods')
# names(eitiCountry) "code_iso_3" "name_official" "name_un" "name_eiti" "language"


#country <- readOGR('data/countriesUN/','2012_UNGIWG_cnt_ply_01')

#dbGetInfo(



mxConfig$defaultZoom = 9

# https://en.wikipedia.org/wiki/GIS_file_formats
# http://www.w3schools.com/tags/att_input_accept.asp
mxConfig$inputDataFileFormat <- list(
  "Shapefile" = list(
    name = "shapefile",
    type = "vector",
    fileExt = c(".shp",".shx",".dbf",".prj"),
    multiple = TRUE
    ),
  "GeoJSON" = list(
    name = "geojson",
    type = "vector",
    fileExt = c(".json",".geojson"),
    multiple = FALSE
    )
  )

mxConfig$inputDataClass <- list(
 
  )




#
# set available palettes
#


mxConfig$colorPalettes = c(
  "Blues",
  "BuGn",
  "BuPu",
  "GnBu",
  "Greens",
  "Greys",
  "Oranges",
  "OrRd",
  "PuBu",
  "PuBuGn",
  "PuRd",
  "Purples",
  "RdPu",
  "Reds",
  "YlGn",
  "YlGnBu",
  "YlOrBr",
  "YlOrRd"
  )


#
# country data
#

countryEitiTable <- import('data/countriesEiti.ods')
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
      paste0("<li><a href=?country=",countryList$pending,"#sectionCountry>",names(countryList$pending),"</a></li>",collapse=""),
      paste0("<li class='dropdown-header'>Potential</li>"),
      paste0("<li><a href=?country=",countryList$potential,"#sectionCountry>",names(countryList$potential),"</a></li>",collapse="")
      )
  )


mxData$countryInfo <- fromJSON('data/countriesEitiStory.json')


#
# list of tile provider
#

mxConfig$tileProviders = list(
  "Default" = "NO_LAYER",
  "Simple I" = "CartoDB.PositronNoLabels",
  "Simple II" = "Hydda.Base",
  "Dark" = "CartoDB.DarkMatterNoLabels",
  "HillShade" = "Acetate.hillshading",
  "Shaded relief" = "HERE.satelliteDay",
  "Terrain" ="Esri.WorldTerrain",
  "Acetate" = "Acetate.terrain",
  "Satellite I" = "HERE.satelliteDay",
  "Satellite II" = "MapQuestOpen.Aerial" 
  )






#
# SET DATA CLASSES
#


mxConfig$class = list(
  "Development" = "dev",
  "Environment" = "env",
  "Natural resources" = "res",
  "Stresses" = "str"
  )


mxConfig$subclass = list(
  'dev' = list(
    'Unemployment'='unemployment',
    'Poverty' ='poverty'
    ),
  'env' = list(
    'Forestry'='forestry',
    'Biodiversity'='biodiversity'
    ),
  'res' = list(
    'Mines'='mines',
    "Oil"='oil',
    "Forestry"="forestry"
    ),
  'str'=list()
  )


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
#
#
#
#datSeries <-xts
#
#
#ggplot(
#  data = dat, 
#  aes(
#    x = year, 
#    y = NY.GDP.PCAP.KD, 
#    color = country)
#  ) + 
#geom_line() + 
#xlab('Year') + ylab('GDP per capita')
