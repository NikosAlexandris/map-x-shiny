#
# ui
#

#
# New story creator btn
#
#observeEvent(input$btnStoryNew,{

  #allowCreate <- isTRUE(reactUser$allowStoryCreator)
  #correctMode <- isTRUE(reactUi$panelMode=="mapStoryReader")

  #if( allowCreate && correctMode ){
    #uiStoryNew <- tagList(
      #textInput("txtStoryName","Add new story title"), 
      #conditionalPanel("input.txtStoryName.length>0",
        #tagList(
          #tags$label("Validation"),
          #div(id="validateNewStoryName")
          #)
        #)
      #)

    #listButtons <- list( 
          #actionButton("btnSaveNewStory",
            #label=icon("save"),
            #class="btn btn-modal"
            #)  
      #)

    #ui <- mxPanel(
      #id="storyMapNew",
      #title="New story map",
      #html=uiStoryNew,
      #addCancelButton=TRUE,
      #listActionButton=listButtons
      #)

    #output$panelStoryMap <- renderUI(ui)
  #}
#})

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

  browser()
   if( allowCreate && correctMode ){ 

     mxActionButtonState(id="btnSaveNewStory",disable=TRUE) 
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

    mxUpdateText(
      id="validateNewStoryName",
     
      )

    panModal <- mxPanel(
      id="panConfirmStorySave",
      title="New story map saved.",
      subtitle="Action handler",
      html=p( sprintf("Saved as '%s' with id '%s' and visibility targeting role '%s' "
        ,input$txtStoryName
        ,newId
        ,defaultVisibility
        )
      )  
      )

    output$panelStoryMap <- renderUI(panModal)

    reactMap$updateStorySelector<-runif(1)
    updateTextInput(session,'txtStoryName',value="")
 
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
  mxDebugMsg(sprintf("selected story = %s",input$selectStoryId))
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

          panModal <- mxPanel(
            id="panConfirmStorySave",
            title="Story map saved.",
            subtitle="Action handler",
            html=p(sprintf("Story map saved with visibility set as %s",storyVisibility))
            )

          mxUpdateText(id="panelStoryMap",ui=panModal)

          reactMap$storyContent <- storyText
          reactMap$storyVisibility <- storyVisibility
})
      }
  }
 })
})




observeEvent(input$btnStoryEdit,{
mxCatch(title="Generate story editor UI",{
  allowEdit <- isTRUE(reactUser$allowEditCurrentStory)
  correctMod <- isTRUE(reactUi$panelMode == "mapStoryReader")
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
      span("Drag and drop views from the menu."),
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
      listActionButton=listButtons
      )

    output$panelStoryMap <- renderUI(ui)

  }
 })
})




#observeEvent(input$btnStoryCreator,{

  ##
  ## TODO: check if the user is authorised
  ##
  ##
  ## Create ui

 
  #uiStoryEditor <- tagList(
    ##
    ## Story Editor
    ##
    #span("Drag and drop views from the menu; Drag and drop coordinates from the box below :"),
    #div(id="txtLiveCoordinate",draggable=TRUE),
    #selectizeInput(
      #label = "Set the story visibility",
      #inputId="selStoryVisibility",
      #choices=mxConfig$noData
      #),
    #tags$textarea(id="txtStoryMapEditor", rows=12, cols=80, placeholder="Write a story...",spellcheck="false"),
    ##buttons
    #tags$script(
      #"
      #document.getElementById('txtLiveCoordinate')
      #.addEventListener('dragstart',function(e){
        #var coord = document.getElementById('txtLiveCoordinate').innerHTML;
        #e.dataTransfer.setData('text', coord);
#})"
      #),

    #tags$ul(class="list-inline",
      #tags$li(
        #actionButton(
          #inputId="btnStoryMapEditorUpdate",
          #class="btn-icon btn-square",
          #label=icon("save")
          #)
        #)
      #)
    #)


  #uiStoryCreator<- tagList(
    ##
    ## Tabset with creator components
    ##
    #mxAccordionGroup(id="storyCreator",
      #itemList=list(
        #"edit"=list(
          #"title"="Edit selected story",
          #"condition"=sprintf("input.selectStoryId.length>0 && input.selectStoryId != '%s'",mxConfig$noData),
          #content=tagList(
            #uiStoryEditor
            #)
          #),
        #"new"=list(
          #"title"="Create a story",
          #content=tagList(
            #uiStoryNew
            #)
          #)
        #)
      #)
    #)

  #ui <- mxPanel(id="storyMapEditor",title="Story map editor",html=uiStoryCreator)

  #output$panelStoryMap <- renderUI(ui)
#})







