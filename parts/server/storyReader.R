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


# available story
observe({
  if(mxReact$mapPanelMode != "mapStoryReader") return()

  update <- mxReact$updateStorySelector
  usr <- mxReact$userId
  iso3 <- mxReact$selectCountry


  tblName <- mxConfig$storyMapsTableName
  storyIds <- list()
 
  # validation
  if(
    isTRUE(!noDataCheck(usr)) && 
    isTRUE(!noDataCheck(iso3)) && 
    isTRUE(mxDbExistsTable(tblName))
    ){

      # db : id,user,country,name,desc,content_b64,content_ascii
      q <- sprintf("
        SELECT id, name 
        FROM %1$s 
        WHERE country='%2$s' AND \"archived\"='f' 
        ORDER by \"dateModified\" desc",
        tblName,
        iso3
        )

      res <- mxDbGetQuery(q) 

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

# retrieve story map text by id


observeEvent(input$selectStoryId,{

  id <- input$selectStoryId
  story <-  mxGetStoryMapText(id)

  if(noDataCheck(story)) story = "Write a story ..."

  mxReact$storyMap <- story

})


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
    # TODO: set margin in the mxStoryText instead of adding space
    r <- paste(rep(" ",1000),collapse="")
    txt <- paste(txt,r,sep="")
    # 
    # Send the story to ui
    #
    mxUpdateText(id="mxStoryText",text=txt,addId=T)
  }
})


