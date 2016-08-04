#
# ui
#

#
# New story creator btn
#


#
# New story name validation
#
observeEvent(input$txtStoryName,{
  newStoryName <- input$txtStoryName 

  valid <- mxTextValidation(
    textToTest = newStoryName,
    existingTexts = mxGetStoryMapName(),
    idTextValidation = "validateNewStoryName"
    )

  mxActionButtonState(id="btnSaveNewStory",disable=!valid) 
})
#
# Create new story in DB
#


observeEvent(input$btnSaveNewStory,{

  allowCreate <- isTRUE(reactUser$allowStoryCreator)
  correctMode <- isTRUE(reactUi$panelMode=="mxModeToolBox")




if( allowCreate && correctMode ){ 

     mxActionButtonState(id="btnSaveNewStory",disable=TRUE) 


    # set values
    timeNow <- Sys.time()
     newId <- randomString()
     user <- as.integer(reactUser$data$id)
     country <- reactProject$name
     title <- input$txtStoryName
     content <- mxToJsonForDb(NA)
     defaultVisibility <- "self"
     visibility <- mxToJsonForDb(defaultVisibility)

  mxDebugMsg(
    sprintf("New story %s will be saved as %s "
      , newId
      , title
      )
    )

    newStory <- list(
      id=newId,
      country=country,
      name=title,
      description=as.character(NA),
      editor = user,
      reviewer = 0L,
      revision = 0L,
      validated = TRUE,
      archived = FALSE,
      date_created = timeNow,
      date_modified = timeNow,
      date_validated = timeNow,
      content= content,
      visibility = mxToJsonForDb(defaultVisibility) 
      )

    mxDbAddRow(
      data=newStory,
      table=mxConfig$storyMapsTableName
      )


    #updateTextInput(session,
      #inputId = 'txtStoryName',
      #value=""
      #)


    msg <- sprintf("Saved as '%s' with id '%s' and visibility targeting role '%s' "
        ,input$txtStoryName
        ,newId
        ,defaultVisibility
        )

    mxUpdateText(
      id="validateNewStoryName",
      msg 
      )

    reactMap$updateStorySelector<-runif(1)
 
  }
})

#
# Update text live coordinates
#
observe({
    cen <- sapply(input$mapxMap_center,round,digit=4)
    zoo <- input$mapxMap_zoom
    dat <- c(cen,zoo)
    nms <- c("lng","lat","zoom")
    res <- paste(nms,dat,sep=":",collapse=",")
    reactMap$txtLiveCoordinate <- res
    mxUpdateText(id="txtLiveCoordinate",text=res)
})



#
# Check if the user can edit the current story
#

observeEvent(input$selectStoryId,{

  id <- input$selectStoryId
  allow <- FALSE
  if(!noDataCheck(id)){
    #
    # If this is super user allow edit
    #
    if( "superuser" %in% reactUser$role$role ){
      allow = TRUE
    }else{
      #
      # If the user is the editor, allow edit
      # 
      editor <- mxDbGetQuery(sprintf(
          "SELECT editor
          FROM mx_story_maps
          WHERE id = '%1$s'
          "
          , id
          )
        )$editor

      if(editor == reactUser$data$id){
        allow <- TRUE
      }else{
        #
        # If the user is allowed to edit the editor's data, allow edit
        #
        userInfo <- mxDbGetUserInfoList(id=editor)

        if(!noDataCheck(userInfo)){ 
          # NOTE: if the user does not exists or empty userInfo ? only superuser can edit

        role <- mxGetMaxRole(userInfo=userInfo,project=reactProject$name)$role

        allow <- isTRUE( role %in% reactUser$role$desc$edit ) 
        }
      }
    }
  }

  reactUser$allowEditCurrentStory <- allow

})





#
# Update story map
#

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


          mxUpdateText(
            id = "txtMessageStoryEditor",
            text = sprintf("Story map saved with visibility set as %s",storyVisibility)
            )

          reactMap$storyContent <- storyText
          reactMap$storyVisibility <- storyVisibility
})
      }
  }
 })
})



observeEvent(input$btnStoryDelete,{
  mxCatch(title="Delete story",{

    allowEdit <- isTRUE(reactUser$allowEditCurrentStory)
    correctMod <- isTRUE(reactUi$panelMode == "mxModeStoryMap")

    if( allowEdit && correctMod ){

      panModal <- mxPanel(
        id="panConfirmStoryDelete",
        title="Remove story map.",
        subtitle="Confirmation",
        html=p(sprintf("Are you sure to remove the selected story?")),
        addCancelButton=TRUE,
         listActionButton=list(actionButton("btnStoryDeleteConfirm","Delete"))
        )

      mxUpdateText(id="panelStoryMap",ui=panModal)

    }

 })

})



observeEvent(input$btnStoryDeleteConfirm,{
  id <- input$selectStoryId
  allowEdit <- isTRUE(reactUser$allowEditCurrentStory)
  correctMod <- isTRUE(reactUi$panelMode == "mxModeStoryMap")
  if( allowEdit && correctMod ){

    q <- sprintf("
      DELETE FROM mx_story_maps WHERE id = '%1$s'",
      id
      )

    mxDbGetQuery(q)

    reactMap$updateStorySelector<-runif(1)

  }
})


observeEvent(input$btnStoryEdit,{
mxCatch(title="Generate story editor UI",{
  allowEdit <- isTRUE(reactUser$allowEditCurrentStory)
  correctMod <- isTRUE(reactUi$panelMode == "mxModeStoryMap")
  choicesVisibility <- reactUser$role$desc$publish
  storyVisibility <- reactMap$storyVisibility 

  if( allowEdit && correctMod ){
    #
    # Create ui
    #
    uiStoryEditor <- tagList(
      selectizeInput(
        label = "Set the story visibility",
        inputId = "selStoryVisibility",
        choices = choicesVisibility,
        selected = storyVisibility
        ),
      span(id="txtMessageStoryEditor",""),
      tags$textarea(
        id="txtStoryMapEditor",
        rows=12, 
        cols=80, 
        placeholder="Write a story...",
        spellcheck="false",
        reactMap$storyContent
        ),
      #buttons
      tags$script(
        "
        document.getElementById('txtLiveCoordinate')
        .addEventListener('dragstart',function(e){
          var coord = document.getElementById('txtLiveCoordinate').innerHTML;
          e.dataTransfer.setData('text', coord);
            })"
        )
      )

    listButtons <- list(
          actionButton(
            inputId="btnStoryMapEditorUpdate",
            class="btn btn-modal",
            label=icon("save")
            )
      )

    #
    # Create panel
    #
 ui <- mxPanel(
      id="storyMapEdit",
      title="Edit current story map",
      subtitle=div(id="txtLiveCoordinate",class="draggable",draggable=TRUE,reactMap$txtLiveCoordinate),
      html=uiStoryEditor,
      defaultButtonText="close",
      defaultTextHeight=450,
      background=FALSE,
      addCancelButton=TRUE,
      addOnClickClose=FALSE,
      listActionButton=listButtons
      )

    output$panelStoryMap <- renderUI(ui)

  }
 })
})





