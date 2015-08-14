


options(shiny.maxRequestSize=30*1024^2)

config <- list()
mxData <- list()



# http://unstats.un.org/unsd/methods/m49/m49alpha.htm
# http://eiti.org/countries/reports/compare/download/xls
eitiCountry <- import('data/countriesEiti.ods')
# names(eitiCountry) "code_iso_3" "name_official" "name_un" "name_eiti" "language"


#country <- readOGR('data/countriesUN/','2012_UNGIWG_cnt_ply_01')

#dbGetInfo(



config$defaultZoom = 9

# https://en.wikipedia.org/wiki/GIS_file_formats
# http://www.w3schools.com/tags/att_input_accept.asp
config$inputDataFileFormat <- list(
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

config$inputDataClass <- list(
 
  )



# country list

countryEitiTable <- import('data/countriesEiti.ods')
countryEitiTable$map_x_pending <- as.logical(countryEitiTable$map_x_pending)
countryEitiTable$name_ui <- paste0("<b>",countryEitiTable$name_un,"</b>(<i>",countryEitiTable$name_official,"</i>)")
countryEitiTable$name_ui <- paste0(countryEitiTable$name_un," (",countryEitiTable$name_official,")")
countryList <- list(
  "pending"= as.list(countryEitiTable[countryEitiTable$map_x_pending,"code_iso_3"])  ,
  "waiting"= as.list(countryEitiTable[!countryEitiTable$map_x_pending,"code_iso_3"])
  )
names(countryList$pending) = countryEitiTable[countryEitiTable$map_x_pending,"name_ui"]
names(countryList$waiting) = countryEitiTable[!countryEitiTable$map_x_pending,"name_ui"]

config$countryListChoices = countryList





# list of tile provider


config$tileProviders = list(
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




config$dataClass



config$class = list(
  "Development" = "dev",
  "Environment" = "env",
  "Natural resources" = "res",
  "Stresses" = "str"
  )


config$subclass = list(
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

config$wdiIndicators <- WDIsearch()[,'indicator']
names(config$wdiIndicators) <- WDIsearch()[,'name']



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
