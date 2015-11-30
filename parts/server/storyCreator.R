#
# ui
#



#
# Event
#


# db : id,user,country,name,desc,content_b64,content_ascii

# available story
mxData$storyMaps <- reactive({
  update <- mxReact$updateStoryMaps
  db <- NULL
  usr <- mxReact$userId
  cnt <- mxReact$selectCountry
  tblName <- mxConfig$storyMapsTableName
  if(!noDataCheck(usr) && !noDataCheck(cnt)){

    mxDebugMsg("Update of storymaps reactive function")
    if(tblName %in% mxDbListTable(dbInfo)){
      q <- sprintf("SELECT * FROM %1$s WHERE \"user\"=%2$s AND country='%3$s'",tblName,usr,cnt)
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
  
 
  isolate({
  # save story list for select input only if it has changed
  listStory <- db$id
  names(listStory) <-db$name
  listStoryOld <- mxReact$storyList
  if(is.null(listStoryOld) || !all(listStory %in% listStoryOld)){
    mxReact$storyList <- listStory
  }
 })
  return(db)
})

observe({
  mxDebugMsg("update select story input")
  updateSelectInput(session,"selectStoryId",choices=mxReact$storyList)
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
    if(nchar(storyMap)<1 || storyMap=="4")storyMap="Write a story..."
    updateAceEditor(session,"txtStoryMap",value=storyMap)
  }
 })
})

# observe story map changes
# -update db with change
#- trigger update for story map

observeEvent(input$txtStoryMap,{
  mxCatch(title="Input story map text",{
  storyText <- input$txtStoryMap
  if( isTRUE(mxReact$allowStoryCreator && mxReact$mapPanelMode=="mapStoryCreator")){
    storyId<-input$selectStoryId
    if(isTRUE(storyId %in% mxReact$storyList)){ 
      if(nchar(storyText)>0){
        mxCatch(title="Parsing story and knit",{
          mxDbUpdate(dbInfo,
            table = mxConfig$storyMapsTableName,
            column = "content_b64",
            id = storyId,
            value = mxEncode(storyText) 
            )
          mxUpdateText(id="mxStoryContainerPreview",text=mxParseStory(storyText))
          mxReact$updateStoryMaps <- runif(1)
        })
      }
    }
  }
 })
})


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
  
  if( isTRUE(mxReact$allowStoryCreator && mxReact$mapPanelMode=="mapStoryCreator")){
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



