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
  if( isTRUE(reactUser$allowStoryCreator && reactUi$panelMode=="mapStoryReader")){
    mxDebugMsg("New name requested")
    

    newId <- randomString()
    defaultVisibility = "self"
    timeNow <- Sys.time()

    newStory <- list(
      id=newId,
      country=reactProject$name,
      name=input$txtStoryName,
      description=as.character(NA),
      editor = as.integer(reactUser$data$id),
      reviewer = 0L,
      revision = 0L,
      validated = TRUE,
      archived = FALSE,
      date_created = timeNow,
      date_modified = timeNow,
      date_validated = timeNow,
      content= mxToJsonForDb(NA),
      visibility = mxToJsonForDb(defaultVisibility) 
      )

    mxDbAddRow(
      data=newStory,
      table=mxConfig$storyMapsTableName
      )


    panModal <- mxPanel(
      id="panConfirmStorySave",
      title="New story map saved.",
      subtitle="Action handler",
      html=p(sprintf("Story map saved with visibility set as %s",defaultVisibility))
      )

    mxUpdateText(id="panelAlert",ui=panModal)

    reactMap$updateStorySelector<-runif(1)
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

    if( isTRUE(reactUser$allowStoryCreator)){
      storyId <- input$selectStoryId
      if(nchar(storyText)>0){
        mxCatch(title="Saving story",{
          mxDbUpdate(
            table = mxConfig$storyMapsTableName,
            column = "content",
            idCol = "id",
            id = storyId,
            value = mxToJsonForDb(storyText) 
            )
          mxDbUpdate(
            table = mxConfig$storyMapsTableName,
            column = "visibility",
            idCol = "id",
            id = storyId,
            value = mxToJsonForDb(storyVisibility) 
            )

          panModal <- mxPanel(
            id="panConfirmStorySave",
            title="Story map saved.",
            subtitle="Action handler",
            html=p(sprintf("Story map saved with visibility set as %s",storyVisibility))
            )

          mxUpdateText(id="panelAlert",ui=panModal)

          reactMap$story <- storyText
})
      }
  }
 })
})


