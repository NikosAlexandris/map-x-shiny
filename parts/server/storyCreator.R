#
# ui
#

# name validation
observeEvent(input$txtStoryName,{
  newStoryName <- input$txtStoryName 

  valid <- mxTextValidation(
    textToTest = newStoryName,
    existingTexts = mxGetStoryMapName(),
    idTextValidation = "validateNewStoryName"
    )

  mxActionButtonState(id="btnSaveNewStory",disable=!valid) 
})


# Save new story in db

observeEvent(input$btnSaveNewStory,{
  if( isTRUE(mxReact$allowStoryCreator && mxReact$mapPanelMode=="mapStoryReader")){
    mxDebugMsg("New name requested")
    

    newId <- randomString()
    
    timeNow <- Sys.time()

    defaultVisibility = as.character(jsonlite::toJSON("self"))

    newStory <- list(
      id=newId,
      country=mxReact$selectCountry,
      name=input$txtStoryName,
      description=as.character(NA),
      editor = as.integer(mxReact$userInfo$id),
      reviewer = 0L,
      revision = 0L,
      validated = TRUE,
      archived = FALSE,
      date_created = timeNow,
      date_modified = timeNow,
      date_validated = timeNow,
      content= as.character(jsonlite::toJSON(as.character(NA))),
      visibility = defaultVisibility 
      )

    mxDbAddRow(
      data=newStory,
      table=mxConfig$storyMapsTableName
      )


    mxReact$updateStorySelector<-runif(1)
    updateTextInput(session,'txtStoryName',value="")
 
  }
})

observe({
    cen <- sapply(input$mapxMap_center,round,digit=4)
    zoo <- input$mapxMap_zoom
    dat <- c(cen,zoo)
    nms <- c("lng","lat","zoom")
    res <- paste(nms,dat,sep=":",collapse=",")
    mxUpdateText(id="txtLiveCoordinate",text=res)
})




observeEvent(input$btnStoryMapEditorUpdate,{
  mxCatch(title="Input story map text",{
  storyText <- input$txtStoryMapEditor
  storyVisibility <- input$selStoryVisibility 

  if( isTRUE(mxReact$allowStoryCreator)){
    storyId <- input$selectStoryId
      if(nchar(storyText)>0){
        mxCatch(title="Saving story",{
          mxDbUpdate(
            table = mxConfig$storyMapsTableName,
            column = "content",
            idCol = "id",
            id = storyId,
            value = jsonlite::toJSON(storyText) 
            )
        mxDbUpdate(
            table = mxConfig$storyMapsTableName,
            column = "visibility",
            idCol = "id",
            id = storyId,
            value = jsonlite::toJSON(storyVisibility) 
            )

         mxReact$storyMap <- storyText
        })
    }
  }
 })
})


