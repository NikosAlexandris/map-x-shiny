#                             
#  _ __ ___   __ _ _ __   __  __
# | '_ ` _ \ / _` | '_ \  \ \/ /
# | | | | | | (_| | |_) |  >  < 
# |_| |_| |_|\__,_| .__/  /_/\_\
#                 | |           
#                 |_|           
# story map reader : create list, select and display story map

#
#
#
#  # save story list for select input only if it has changed
#  listStory <- db$id
#  names(listStory) <-db$name
#  listStoryOld <- mxReact$storyList
#
#  # populate reactive list of story. 
#  if(is.null(listStoryOld) || !all(listStory %in% listStoryOld)){
#    mxDebugMsg("Update story list")
#    mxReact$storyList <- listStory
#  }
#  
#

# Allow story map creator
observe({
  if(mxReact$allowStoryCreator){
    source("parts/server/storyCreator.R",local=TRUE)
  }
})

# available story
mxData$storyMaps <- reactive({
  update <- mxReact$updateStoryMaps
  db <- NULL
  usr <- mxReact$userId
  cnt <- mxReact$selectCountry
  tblName <- mxConfig$storyMapsTableName
  if(!noDataCheck(usr) && !noDataCheck(cnt)){

    if(tblName %in% mxDbListTable(dbInfo)){

    mxDebugMsg("Update of storymaps reactive function")
      # db : id,user,country,name,desc,content_b64,content_ascii
# user only   q <- sprintf("SELECT * FROM %1$s WHERE \"user\"=%2$s AND country='%3$s'",tblName,usr,cnt)
      q <- sprintf("SELECT * FROM %1$s WHERE country='%2$s'",tblName,cnt)
      db <- mxDbGetQuery(dbInfo,q) 
    }else{
      # empty
      db <- data.frame(
        id=NA,
        user=usr,
        country=cnt,
        name=NA,
        desc=NA,

        content_b64=NA,
        content_ascii=NA
        )
    }
  } 
   return(db)
})


observe({
  # first evaluation, then at update only.
  update <- mxReact$updateStoryMaps
  db <- mxData$storyMaps() 
  listStory <- db$id
  names(listStory) <-db$name
  updateSelectizeInput(session,"selectStoryId",choices=listStory,server=TRUE,selected=listStory[1])
})



# observe choosen story
# - Read corresponding story from storymaps
# - update editor
observeEvent(input$selectStoryId,{
mxCatch(title="Select story id",{
  storyId <- input$selectStoryId
  mxDebugMsg(paste("Select story id=",storyId))
  if(!noDataCheck(storyId,noDataVal="NA")){
    storyMap <- mxData$storyMaps()
    storyMap <- mxDecode(storyMap[storyMap$id==storyId,"content_b64"])
    if(nchar(storyMap)>0){
      mxReact$storyMap <- storyMap
    }
     }
 })
})


observe({
  storyMarkdown <- mxReact$storyMap
  if(!noDataCheck(storyMarkdown)){
    txt <- mxParseStory(storyMarkdown)
    r <- paste(rep(" ",1000),collapse="")
    txt <- paste(txt,r,sep="")
    mxUpdateText(id="mxStoryContainerPreview",text=txt,addId=T)
  }
})


observe({
  storyMarkdown <- mxReact$storyMap
  if(!noDataCheck(storyMarkdown)){
    mxUpdateText(id="txtStoryMap",text=storyMarkdown)
  }
})



