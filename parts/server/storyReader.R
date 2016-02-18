#                             
#  _ __ ___   __ _ _ __   __  __
# | '_ ` _ \ / _` | '_ \  \ \/ /
# | | | | | | (_| | |_) |  >  < 
# |_| |_| |_|\__,_| .__/  /_/\_\
#                 | |           
#                 |_|           
# story map reader : create list, select and display story map



# Allow story map creator
observe({
  if(mxReact$allowStoryCreator){
    source("parts/server/storyCreator.R",local=TRUE)
  }
})


mxGetStoryMapText <- function(dbInfo,id,textColumn="content_b64"){
  tblName <- mxConfig$storyMapsTableName
  res <- data.frame()
  if(mxDbExistsTable(dbInfo,tblName)){
    q <- sprintf("SELECT %1$s FROM %2$s WHERE \"id\"='%3$s' and \"archived\"='f'",
      textColumn,
      tblName,
      id
      )
    res <- mxDbGetQuery(dbInfo,q) 
  }
  if(textColumn %in% names(res)){
  res <- mxDecode(res$content_b64)
  }
  return(res)
}


mxGetStoryMapName <- function(dbInfo){
  tblName <- mxConfig$storyMapsTableName
  if(!mxDbExistsTable(dbInfo,tblName)) return(data.frame())
  q <- sprintf("SELECT name FROM %1$s WHERE \"archived\"='f'",tblName)
  res <- mxDbGetQuery(dbInfo,q) 
  return(res)
}

# available story
observe({
  if(mxReact$mapPanelMode != "mapStoryReader") return()

  update <- mxReact$updateStorySelector
  usr <- mxReact$userId
  iso3 <- mxReact$selectCountry
  panelMode <- mxReact$mapPanelMode 


  tblName <- mxConfig$storyMapsTableName
  storyIds <- list()
 
  # validation
  if(
    isTRUE(!noDataCheck(usr)) && 
    isTRUE(!noDataCheck(iso3)) && 
    isTRUE(panelMode == "mapStoryReader") &&
    isTRUE(mxDbExistsTable(dbInfo,tblName))
    ){

      # db : id,user,country,name,desc,content_b64,content_ascii
      q <- sprintf("SELECT id, name FROM %1$s WHERE country='%2$s' AND \"archived\"='f' order by \"dateModified\" desc",tblName,iso3)
      res <- mxDbGetQuery(dbInfo,q) 

      storyIds <- res$id
      names(storyIds) <-res$name
   
      updateSelectizeInput(session,
        "selectStoryId",
        choices=storyIds,
        server=TRUE,
        selected=storyIds[1]
        )
    }
})


observeEvent(input$selectStoryId,{
id <- input$selectStoryId

story <-  mxGetStoryMapText(dbInfo,id)

if(noDataCheck(story)) story = "Write a story ..."

mxReact$storyMap <- story
  
})



#observe({
#mxCatch(title="Update story selector",{

  #if(mxReact$mapPanelMode != "mapStoryReader") return()
  #mxDebugMsg("Update story selectize input")
  ##
  ## Update story map selector 
  ##
  #db <- mxData$storyMaps() 
  #listStory <- db$id
  #names(listStory) <-db$name
  #updateSelectizeInput(session,"selectStoryId",choices=listStory,server=TRUE,selected=listStory[1])
    #})
#})


#observeEvent(input$selectStoryId,{
  #mxCatch(title="Select story id",{
    ##
    ## Decode selected story
    ##
    #storyId <- input$selectStoryId
    #storyMap <- "Write a story.."
    #if(!noDataCheck(storyId,noDataVal="NA")){
      #storyMap <- mxData$storyMaps() 
      #storyMap <- storyMap[storyMap$id==storyId,"content_b64"]
      #if(is.na(storyMap)){
        #storyMap <- "Write a story.."
      #}else{
        #storyMap <- mxDecode(storyMap)
      #}
    #}else{
      #storyMap = " No story map yet :( "
    #}
    #mxReact$storyMap <- storyMap

    #})
#})


observeEvent(mxReact$storyMap,{
  storyMap <- mxReact$storyMap
  if(!noDataCheck( storyMap )){
    #
    # Update editor
    #
    mxUpdateValue(id="txtStoryMapEditor",value=storyMap)
    #
    # Parse story map
    #
    txt <- mxParseStory( storyMap )
    # add some blank space
    r <- paste(rep(" ",1000),collapse="")
    txt <- paste(txt,r,sep="")
    # 
    # Send the story to ui
    #
    mxUpdateText(id="mxStoryText",text=txt,addId=T)
  }
})


