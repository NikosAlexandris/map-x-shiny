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

    df <- data.frame(
      id=newId,
      user=as.integer(mxReact$userId),
      country=mxReact$selectCountry,
      name=input$txtStoryName,
      desc=as.character(NA),
      content_b64=as.character(NA),
      content_ascii=as.character(NA),
      editor = mxReact$userId,
      reviever = "",
      revision = 0,
      validated = TRUE,
      archived = FALSE,
      dateCreated = timeNow,
      dateArchived = as.POSIXct(as.Date(0,origin="1970/01/01")),
      dateModified = timeNow,
      dateValidated = timeNow
      )

    mxDbAddData(table=mxConfig$storyMapsTableName, data=df )
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
  if( isTRUE(mxReact$allowStoryCreator)){
    storyId <- input$selectStoryId
      if(nchar(storyText)>0){
        mxCatch(title="Saving story",{
          mxDbUpdate(
            table = mxConfig$storyMapsTableName,
            column = "content_b64",
            id = storyId,
            value = mxEncode(storyText) 
            )
         mxReact$storyMap <- storyText
        })
    }
  }
 })
})


