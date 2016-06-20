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
#  !!! THIS PART NEED WORK : THERE IS NEARLY NO LOGIC OF READ / WRITE ACCESS !!!
#
#
#



# Allow story map creator
observe({
  if(reactUser$allowStoryCreator){
    source("parts/server/storyCreator.R",local=TRUE)
  }
})


# available story
observe({
  if(reactUi$panelMode != "mapStoryReader") return()
  # default
  choice <- mxConfig$noData
  # take reactivity on select input

  cntry <- toupper(reactProject$name)
  # reactivity after updateVector in postgis
  update <- reactMap$updateStorySelector 

  usr <- reactUser$data
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
      
      #
      # Update choice, set default to the last read story
      #
      isolate({

        idOld <- mxGetListValue(
          li=usr,
          path = c("data","user","cache","last_story")
          )

        if(noDataCheck(idOld)){
          id = input$selectStoryId
        }else{
          id = idOld
        }

        if(noDataCheck(id)) id = choice

        updateSelectizeInput(session,
          "selectStoryId",
          choices = c(storyIds,choice),
          server = TRUE,
          selected = input$selectStoryId
          )
      })

})
  }


})


#
# retrieve story map text by id
#

observeEvent(input$selectStoryId,{
  #
  # get story map id
  #
  id <- input$selectStoryId
  if(noDataCheck(id)) return()
  #
  # update reactive value and db if needed
  #
  mxDbUpdateUserData(reactUser,
    path=c("data","user","cache","last_story"),
    value=selCountry
    )
  #
  # Retrieve story by id
  #
  story <-  mxGetStoryMapData(id)
  if( reactUser$allowStoryCreator ){
    #
    # Set select story visibility (editor)
    #
    if(!noDataCheck(story$visibility)){
      updateSelectizeInput(
        session,
        inputId="selStoryVisibility",
        selected=story$visibility
        )
    }
  }
  #
  # If no content, set default text
  #
  if(noDataCheck(story$content)){
    story = "Write a story ..."
  }else{
    story = story$content
  }
  #
  # Update current story map
  #
  reactMap$story <- story

})


observeEvent(reactMap$story,{
  storyMap <- reactMap$story
  if(!noDataCheck( storyMap )){



    if( reactUser$allowStoryCreator ){
      #
      # Update editor
      #
      mxUpdateValue(id="txtStoryMapEditor",value=storyMap)
    }
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


