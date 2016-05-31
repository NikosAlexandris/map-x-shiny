#                             
#  _ __ ___   __ _ _ __   __  __
# | '_ ` _ \ / _` | '_ \  \ \/ /
# | | | | | | (_| | |_) |  >  < 
# |_| |_| |_|\__,_| .__/  /_/\_\
#                 | |           
#                 |_|           
# view creator management


#observe({
  #if(mxReact$allowViewsCreator){
    #class = input$selNewLayerClass
    #if(!noDataCheck(class)){
      #updateSelectInput(session,"selNewLayerSubClass",choices=mxConfig$subclass[[class]])
    #}
  #}
#})

#
# Btn refresh
#



#observeEvent(input$btnViewsRefresh,{
  #if(mxReact$allowViewsCreator){
    #mxDebugMsg("Command remote server to restart app")
    #if( mxConfig$hostname != mxConfig$remoteHostname ){
      #remoteCmd(mxConfig$remoteHostname,cmd=mxConfig$restartPgRestApi)
    #}else{
      #system(mxConfig$restartPgRestApi)
    #}
    #mxReact$layerListUpdate <- runif(1) 
  #}
#})





#
# Populate layer selection
#
observe({
  if(mxReact$allowViewsCreator){
    # default
    choice <- mxConfig$noData
    # take reactivity on select input

    cntry <- toupper(mxReact$selectCountry)
    # reactivity after updateVector in postgis
    update <- mxReact$layerListUpdate

    usr <- mxReact$userInfo
    visibility = paste0("'",usr$role$desc$read,"'",collapse=",")

    if(!noDataCheck(visibility)){
      mxCatch("Update input: get list of layer",{

        sql <- gsub("\n","",sprintf(
            "SELECT layer 
            FROM mx_layers 
            WHERE country='%1$s' AND
            ( visibility ?| array[%2$s] OR editor = '%3$s' )",
            cntry,
            visibility,
            usr$id
            ))


        layers <- mxDbGetQuery(sql)$layer

        if(!noDataCheck(layers)){
          choice = c(choice,layers)  
        }
        updateSelectInput(session,"selLayer",choices=choice)
        mxReact$layerList = choice
      })
    }
  }
})


#
# Populate column selection
# 

observeEvent(input$selLayer,{
  if(mxReact$allowViewsCreator){
    # take reactivity on layer selection
    lay = input$selLayer
    # Default variables
    vars = mxConfig$noData
    # check if it has date cols
    hasDate = FALSE
    # if layer is not empty:
    # - get available variables
    # - check for map x dates variables
    # - save in mxStyle
    # - update select input with available variable

    if(!noDataCheck(lay)){
      mxCatch("Update input: layer columns",{

        variables <- mxDbGetColumnsNames(lay)
      

        if(!noDataCheck(variables)){
          vars = variables[ !variables %in% c("gid","geom") ]
        } 
        # Date handling 
        hasDate <- isTRUE("mx_date_start" %in% vars) && isTRUE( "mx_date_end" %in% vars)
        # Set mxStyle
        mxStyle$layer <- lay
        mxStyle$group <- mxConfig$defaultGroup
        mxStyle$hasDateColumns <- hasDate
      })
    }

    # NOTE: bug with code and parties. After code, no variable can be set on extractive mineral layer 
    varsLess <- vars[!vars %in% c("code","parties")]
    updateSelectInput(session, "selColumnVar", choices=varsLess)
    updateSelectInput(session, "selColumnVarToKeep", choices=c(mxConfig$noVariable,vars),selected=vars[1])
  }
})


#
# get selected variable summary, set mxStyle accordingly and update palette choice.
#

observeEvent(input$selColumnVar,{
  if(mxReact$allowViewsCreator){
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
        # From now, we have enough info to begin mxStyle setting.
        mxStyle$variable      <- var
        mxStyle$scaleType     <- layerSummary$scaleType
        mxStyle$values        <- layerSummary$dValues
        mxStyle$nDistinct     <- layerSummary$nDistinct
        mxStyle$nMissing      <- layerSummary$nNa
        mxStyle$paletteChoice <- paletteChoice
      }
  }
})


#
# Set other layer options based on inputs
#


observe({
  mxStyle$title <-  input$mapViewTitle 
})

observe({
  mxStyle$palette  <- if(!noDataCheck(input$selPalette))input$selPalette
})

observe({
  mxStyle$opacity <- if(!noDataCheck(input$selOpacity))input$selOpacity
})

observe({
  mxStyle$basemap <- if(!noDataCheck(input$selectBaseMap))input$selectBaseMap
})

observe({
  mxStyle$size <- if(!noDataCheck(input$selSize))input$selSize
})

observe({
  mxStyle$hideLabels <- if(!noDataCheck(input$checkBoxHideLabels))input$checkBoxHideLabels
})

observe({
  mxStyle$hideLegends <- if(!noDataCheck(input$checkBoxHideLegends)) input$checkBoxHideLegends 
})

observe({
  mxStyle$variableUnit <- input$txtVarUnit
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
  if(mxReact$enableViewsCreator){
    mxCatch(title="Save style",{
      #sty2<-layerStyle()
      sty <- reactiveValuesToList(mxStyle)
      # save additional variables
      hasDate <- mxStyle$hasDateColumns
      vToKeep <- input$selColumnVarToKeep
      vToKeep <- vToKeep[!vToKeep %in% mxConfig$noVariable]
      if(isTRUE(hasDate)){
        vToKeep <- unique(c("mx_date_start","mx_date_end",vToKeep))
      }
      sty$variableToKeep <- vToKeep

      #
      # Visibility
      #

      visibility <- as.character(jsonlite::toJSON(input$selNewViewVisibility))

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
          country = mxReact$selectCountry,
          title = input$mapViewTitle,
          class = input$mapViewClass,
          layer = sty$layer,
          editor = mxReact$userInfo$id,
          reviewer = 0L,
          revision = 0L,
          validated = TRUE,
          archived = FALSE,
          date_created = timeNow,
          date_modified = timeNow,
          date_validated = timeNow,
          date_archived = timeNow,
          style = as.character(jsonlite::toJSON(sty)),
          visibility = visibility
          )


      mxDbAddRow(
        data = view,
        table = viewTable
        )

      mxReact$viewsListUpdate <- runif(1)


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

