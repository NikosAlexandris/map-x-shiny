#
# ui
#

# name validation
observeEvent(input$txtStoryName,{
  newStoryName <- input$txtStoryName 
  valid <- mxTextValidation(
    textToTest = newStoryName,
    existingTexts = mxData$storyMaps()$name,
    idTextValidation = "validateNewStoryName"
    )

  mxActionButtonState(id="btnSaveNewStory",disable=!valid) 
})


# Save new story in db

observeEvent(input$btnSaveNewStory,{
  if( isTRUE(mxReact$allowStoryCreator && mxReact$mapPanelMode=="mapStoryReader")){
    mxDebugMsg("New name requested")
    df <- data.frame(
      id=randomName(),
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
      dateCreated = date(),
      dataModifed = date(),
      dateValidated = date()
      )

    mxReact$updateStoryMaps<-runif(1)
    mxDbAddData(dbInfo,table=mxConfig$storyMapsTableName, data=df )
    updateTextInput(session,'txtStoryName',value="")
  }
})


observe({
    bnd <- input$mapxMap_bounds
    bnd <- lapply(bnd,round,digits=4) # ~ 11 m
    nms <- sapply(names(bnd),substr,1,1)
    res <- paste(nms,bnd,sep=":",collapse=",")
    mxUpdateText(id="txtLiveCoordinate",text=res)
})



observeEvent(input$btnStoryMapEditorUpdate,{
  mxCatch(title="Input story map text",{
  storyText <- input$txtStoryMap
  if( isTRUE(mxReact$allowStoryCreator)){
    storyId <- input$selectStoryId
      if(nchar(storyText)>0){
        mxCatch(title="Parsing story and knit",{
          mxDbUpdate(dbInfo,
            table = mxConfig$storyMapsTableName,
            column = "content_b64",
            id = storyId,
            value = mxEncode(storyText) 
            )
          mxUpdateText(id="mxStoryContainerPreview",text=mxParseStory(storyText))
         mxReact$storyMap <- mxParseStory(storyText) 
        })
    }
  }
 })
})


