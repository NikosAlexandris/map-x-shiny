#                             
#  _ __ ___   __ _ _ __   __  __
# | '_ ` _ \ / _` | '_ \  \ \/ /
# | | | | | | (_| | |_) |  >  < 
# |_| |_| |_|\__,_| .__/  /_/\_\
#                 | |           
#                 |_|           
# view creator management



#
# Populate layer selection
#
observe({
  mxCatch("Update input: get list of layer",{
    # chech if the user as access to creator  
    allow <- reactUser$allowViewsCreator
    # current country / project
    cntry <- toupper(reactProject$name)
    # update trigger
    update <- reactMap$layerListUpdate
    # user information
    roles <- reactUser$role
    data <- reactUser$data
    canRead <- roles$desc$read
    # no data test
    hasRole <- !noDataCheck(roles)
    hasReadLevel <- !noDataCheck(canRead)
    hasData <- !noDataCheck(data)
    # Default
    choice <- mxConfig$noData
    #
    # update choice
    #
    if(allow && hasData && hasReadLevel && hasReadLevel){
      # fetch layers list
      layers <- mxDbGetLayerList(
        project=cntry,
        visibility=canRead,
        userId=data$id
        )
      # if there is at least one layers, update choices
      if(!noDataCheck(layers)){
        choice = layers
      }
    }

    # update ui
    updateSelectInput(session,"selLayer",choices=choice)
    # store value
    reactMap$layerList <- choice
})
})


#
# Populate column selection
# 

observe({
  mxCatch("Update input: layer columns",{

  modeCreator <- isTRUE( reactUi$panelMode == "mxModeToolBox" )

    # get user values
    allow <- reactUser$allowViewsCreator
    # get selected layer
    layer <- input$selLayer
    # defaults
    variables <- mxConfig$noData
    hasDate <- FALSE
    # test
    layerIsOk <- isTRUE(!noDataCheck(layer) && layer %in% reactMap$layerList)

    # Update variables
    if( allow && layerIsOk && modeCreator ){

      # fetch variables name
      variables <- mxDbGetColumnsNames(layer)
      # subset value
      if(!noDataCheck(variables)){
        vars = variables[ !variables %in% c("gid","geom") ]
      } 
      # Date handling 
      hasDate <- isTRUE("mx_date_start" %in% vars) && isTRUE( "mx_date_end" %in% vars)
      # Set reactStyle
      reactStyle$layer <- layer
      reactStyle$group <- mxConfig$defaultGroup
      reactStyle$hasDateColumns <- hasDate
      # NOTE: bug with code and parties. After code, no variable can be set on extractive mineral layer 
      varsLess <- vars[!vars %in% c("code","parties")]
      # update variable to use for styling
      updateSelectInput(
        session, 
        inputId="selColumnVar", 
        choices=varsLess
        )
      # update additional variable to keep
      updateSelectInput(session, 
        inputId="selColumnVarToKeep", 
        choices=c(mxConfig$noVariable,vars)
        )
    }

})
})


#
# get selected variable summary, set reactStyle accordingly and update palette choice.
#

observeEvent(input$selColumnVar,{
  if(reactUser$allowViewsCreator){
    lay = input$selLayer
    var = input$selColumnVar
      if(!noDataCheck(lay) && !noDataCheck(var)){
        # extract layer summary from postgres
        layerSummary <- mxDbGetColumnInfo(lay,var)
        if(noDataCheck(layerSummary)){
          return(NULL)
        }
        # set palette choice
        paletteChoice         <- mxConfig$colorPalettes
        updateSelectInput(session,"selPalette",choices=paletteChoice)
        # From now, we have enough info to begin reactStyle setting.
        reactStyle$variable      <- var
        reactStyle$scaleType     <- layerSummary$scaleType
        reactStyle$values        <- layerSummary$dValues
        reactStyle$nDistinct     <- layerSummary$nDistinct
        reactStyle$nMissing      <- layerSummary$nNa
        reactStyle$paletteChoice <- paletteChoice
      }
  }
})


#
# Set other layer options based on inputs
#


observe({
  reactStyle$title <-  input$mapViewTitle 
})

observe({
  reactStyle$palette  <- if(!noDataCheck(input$selPalette))input$selPalette
})

observe({
  reactStyle$opacity <- if(!noDataCheck(input$selOpacity))input$selOpacity
})

observe({
  reactStyle$basemap <- if(!noDataCheck(input$selectBaseMap))input$selectBaseMap
})

observe({
  reactStyle$size <- if(!noDataCheck(input$selSize))input$selSize
})

observe({
  reactStyle$hideLabels <- if(!noDataCheck(input$checkBoxHideLabels))input$checkBoxHideLabels
})

observe({
  reactStyle$hideLegends <- if(!noDataCheck(input$checkBoxHideLegends)) input$checkBoxHideLegends 
})

observe({
  reactStyle$variableUnit <- input$txtVarUnit
})


observe({
  titleOk <- !noDataCheck(input$mapViewTitle)
  layerOk <- !noDataCheck(input$selLayer)
  varOk <- !noDataCheck(input$selColumnVar)
  palOk <- !noDataCheck(input$selPalette)
  descOk <- !noDataCheck(input$txtViewDescription)
  allowSaveView <- FALSE
  if(all(c(titleOk,layerOk,varOk,palOk,descOk))){
    allowSaveView <- TRUE
  }
  mxActionButtonState(id="btnViewCreatorSave",disable=!allowSaveView) 
})



#
# SAVE STYLE
# 

observeEvent(input$btnViewCreatorSave,{
  if(reactUser$allowViewsCreator){
    mxCatch(title="Save style",{
      #sty2<-layerStyle()
      sty <- reactiveValuesToList(reactStyle)
      # save additional variables
      hasDate <- reactStyle$hasDateColumns
      vToKeep <- input$selColumnVarToKeep
      vToKeep <- vToKeep[!vToKeep %in% mxConfig$noVariable]
      if(isTRUE(hasDate)){
        vToKeep <- unique(c("mx_date_start","mx_date_end",vToKeep))
      }
      sty$variableToKeep <- vToKeep

      #
      # Visibility
      #

      visibility <- input$selNewViewVisibility

      #
      # Date handler
      #

      sty$hasDateColumns <- isTRUE(hasDate)

      if(sty$hasDateColumns){
            q <- sprintf("SELECT min(mx_date_start),max(mx_date_end) FROM %s;",sty$layer)
            mxDate <- mxDbGetQuery(q)
            sty$dateMax <- as.Date(as.POSIXct(max(mxDate), origin="1970-01-01"))
            sty$dateMin <- as.Date(as.POSIXct(min(mxDate), origin="1970-01-01"))
      }


      #
      # Companies
      #
      companyColName = "parties"
      sty$hasCompanyColumn <- isTRUE(companyColName %in% vToKeep)

      if(sty$hasCompanyColumn){
          q <- sprintf(
            "SELECT DISTINCT(%1$s) FROM %2$s ORDER BY %1$s",
            companyColName,
            sty$layer
            )
          sty$companies <- mxDbGetQuery(q)[[ companyColName ]] 
      }


      #
      # Description
      #

      sty$description <- input$txtViewDescription
 
      #
      # Save table n
      #

      viewTable <- mxConfig$viewsListTableName
      timeNow <- Sys.time()

      view = list(
          id =  randomString(),
          country = reactProject$name,
          title = input$mapViewTitle,
          class = input$mapViewClass,
          layer = sty$layer,
          editor = reactUser$data$id,
          reviewer = 0L,
          revision = 0L,
          validated = TRUE,
          archived = FALSE,
          date_created = timeNow,
          date_modified = timeNow,
          date_validated = timeNow,
          date_archived = timeNow,
          style = mxToJsonForDb(sty),
          visibility = mxToJsonForDb(visibility)
          )


      mxDbAddRow(
        data = view,
        table = viewTable
        )

      reactMap$viewsDataListUpdate <- runif(1)


 panModal <- mxPanel(
      id="panImportModal",
      title="View creation done",
      subtitle="Action handler",
      html=p("Creation done. Please check if the view is available.")
      )

    mxUpdateText(id="panelAlert",ui=panModal)

      output$txtValidationCreator = renderText({"ok."})
    })
  }
})

#
# Edit current view
#

observeEvent(input$mxEditView,{
id <- input$mxEditView
pan <- mxPanel(title="Edit view",subtitle=sprintf("id=%s",id))
output$panelAlert <- renderUI(pan)
})




