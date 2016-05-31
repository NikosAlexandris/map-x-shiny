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
  # default
  choice <- mxConfig$noData
  # take reactivity on select input

  cntry <- toupper(mxReact$selectCountry)
  # reactivity after updateVector in postgis
  update <- mxReact$updateStorySelector 

  usr <- mxReact$userInfo
  storyPath <- c("data","user","preferences","last_story")
  visibility <- usr$role$desc$read
  visibility = paste0("'",visibility[!visibility %in% 'self'],"'",collapse=",")

  if(!noDataCheck(visibility)){
    mxCatch("Update input: get list of story maps",{

      sql <- gsub("\n","",sprintf(
          "SELECT id, name 
          FROM mx_story_maps
          WHERE country='%1$s' AND
          ( visibility ?| array[%2$s] OR editor = '%3$s' )",
          cntry,
          visibility,
          usr$id
          ))


      res <- mxDbGetQuery(sql)

      storyIds <- res$id
      names(storyIds) <-res$name

      if(!noDataCheck(storyIds)){
        choice = c(storyIds,choice)  
      }
      isolate({

        idOld <- mxGetListValue(
          li=usr,
          path=storyPath
          )

        if(noDataCheck(idOld)){
          id = input$selectStoryId
        }else{
          id = idOld
        }

        if(noDataCheck(id)) id = choice

        updateSelectizeInput(session,
          "selectStoryId",
          choices=c(storyIds,choice),
          server=TRUE,
          selected=input$selectStoryId
          )
      })

})
  }


})


#
# retrieve story map text by id
#

observeEvent(input$selectStoryId,{

  id <- input$selectStoryId

  if(noDataCheck(id)) return()

  #
  # Save id in database
  #

  dat <- mxReact$userInfo
  storyPath = c("data","user","preferences","last_story")

  idOld <- mxGetListValue(
      li=dat,
      path=storyPath
      ) 

   if(!identical(idOld,id)){
      dat <- mxSetListValue(
        li=dat,
        path=storyPath,
        value=id
        )
      
      mxDbUpdate(
        table=mxConfig$userTableName,
        idCol='id',
        id=dat$id,
        column='data',
        value=dat$data
        )
    }

  story <-  mxGetStoryMapData(id)
  if(!noDataCheck(story$visibility)){
  updateSelectizeInput(
    session,
    inputId="selStoryVisibility",
    selected=story$visibility
    )
  }

  if(noDataCheck(story$content)){
    story = "Write a story ..."
  }else{
    story = story$content
  }

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


