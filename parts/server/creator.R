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
# Parse meta from input
#
observe({
  out = list()
  try(silent=T,{
    # Silent because this function can very likely return an error 
    out <- mxParseListFromText(input$txtNewLayerMeta)
})
  mxReact$newLayerMeta = out
})


# new layer name validation

observe({
  if(mxReact$allowViewsCreator && mxReact$mapPanelMode == "mapViewsCreator" ){
    err = character(0)
    info = character(0)
    out  = character(0)
    valid = FALSE
    msgList = character(0)


    #
    # Layer name warning
    #
    cty <- mxReact$selectCountry
    #yea <- input$selNewLayerYear
    cla <- input$selNewLayerClass
    sub <- subPunct(input$txtNewLayerTags)
    met <- mxReact$newLayerMeta

    #newLayerName <- tolower( paste0(cty,"__",yea,"__",cla,"__",sub))
    newLayerName <- tolower( paste0(cty,"__",cla,"__",sub))

    exist <- mxTextValidation(
      textToTest = newLayerName,
      existingTexts = mxReact$layerList,
      idTextValidation = "outNewLayerNameValidation",
      existsText = "overwrite",
      errorColor = "#ff9900"
      )

    #
    # other validation
    #

    #mxDebugToJs(met)

    tagMissing <- isTRUE(nchar(sub) < 2)
    metMissing <- isTRUE(length(met) < 1)

    if(tagMissing) err <- c(err,"Tag(s) missing")
    if(metMissing) err <- c(err,"Source entry missing")


    if(length(err)>0){
      outTxt = sprintf("<b style=\"color:%1$s\">(%2$s)</b> %3$s","#FF0000","issue",err,"</br>")
      outTxt = paste("<hr/><ul class='nav'>",paste("<li>",outTxt,"</li>",collapse="",sep=""),"</ul><hr/>")
      valid = FALSE
    }else{
      outTxt = ""
      valid = TRUE
    }

    mxUpdateText(id="outNewLayerErrors",text=HTML(outTxt))

    mxActionButtonState(id="fileNewLayer",disable=!valid, warning=!exist) 

    mxReact$newLayerName <- ifelse(valid,newLayerName,"")
  }
})


#
#  FILE HANDLER : VALIDATION AND PSQL 
#


observeEvent(input$fileNewLayer,{

  if(mxReact$allowViewsCreator){

    met <- mxReact$newLayerMeta
    src <- input$fileNewLayer$datapath
    nam <- mxReact$newLayerName 
    cla <- input$selNewLayerClass
    tgs <- subPunct(input$txtNewLayerTags)

    lInfo = ogrinfo(
      src,
      "OGRGeoJSON",
      ro=TRUE,
      so=TRUE
      )

    #
    # CHECK FILE FORMAT
    #
    isGeojson = isTRUE(length(grep("OGRGeoJSON",lInfo)[1])>0) 

    if(!isGeojson){
      msg <- ("Data imported is not in format 'geojson'")
      mxUpdateText("outLayerFileMsg",msg)
      return()
    }

    #
    # CHECK SRID 
    #
    projOk = isTRUE(
      length(grep("(AUTHORITY).+(EPSG).+(4326)",lInfo)) > 0 &&
      length(grep("(GEOGCS).*(WGS 84)",lInfo)) >0
      )

    if(!projOk){
      msg <- "Error before importation : srid is not '4326'"
      mxUpdateText("outLayerFileMsg",msg)
      return()
    }
    #
    # Return summary list
    #

    mxReact$newLayerSummary = list(
      class = cla,
      tags = tgs,
      name = nam,
      meta = met,
      srid = ifelse(projOk,"4326","nodata"),
      file = src
      )

  }

})



observeEvent(mxReact$newLayerSummary,{

  sl <- mxReact$newLayerSummary 
  if(TRUE){
    sl <- HTML(listToHtmlClass(sl,exclude="file"))
    ui<-tagList(div(class="mx-panel-400",
        h6("Upload done"),
        p("Please review DB importation before continuing:"),
        sl
        )
      )
    bnts <- tagList(
      actionButton("btnDbImportConfirm","confirm",class="btn-modal")
      )
    panModal <- mxPanel(
      id="panImportModal",
      title="Import new layer in database.",
      subtitle="Action handler",
      html=ui,
      listActionButton=bnts,
      addCancelButton=TRUE
      )

    mxUpdateText(id="panelAlert",ui=panModal)
  }

})



#
# Observe button of confirmation for import into db
#

observeEvent(input$btnDbImportConfirm,{
  mxCatch(title="Import to DB",{


  panModal <- mxPanel(
      id="panImportModal",
      title="Import new layer in database.",
      subtitle="Format conversion",
      html=tags$b("Please wait..."),
      )

    mxUpdateText(id="panelAlert",ui=panModal)



    # summary layer
    sl <- mxReact$newLayerSummary 
    # append in table
    ap <- FALSE
    # table name
    tn <- mxConfig$layersTableName
    # table list
    te <- mxDbExistsTable(dbInfo,tn)
    le <- mxDbExistsTable(dbInfo,sl$name)
    # Revision number
    rn <- 0
    # time now 
    timeNow <- Sys.time()
    #
    # If layer already exists check revision number
    #

    if( le && te ){
      # get revision number
      q <- sprintf("SELECT revision FROM %1$s WHERE layer='%2$s' LIMIT 1",tn,sl$name)
      res <- mxDbGetQuery(dbInfo,q)$revision
      # replace revision number if needed
      if(isTRUE(is.numeric(res))){
        rn <- res + 1
      }
    }
    #
    # Save into layer table
    #
    dbAddGeoJSON(
      dbInfo=dbInfo,
      geojsonPath=sl$file,
      tableName=sl$name,
      archivePrefix = mxConfig$prefixArchiveLayer
      )
    #
    # get existing columns
    #
    cols <- mxDbListColumns(dbInfo,sl$name)

    if(! "mx_date_end" %in% cols && ! "mx_date_start" %in% cols ){
      if("octroyé" %in% cols && "expire" %in% cols){
        # TODO: drop old column, validate date formating.
        # add columns
        qAdd = sprintf(
          "ALTER TABLE %s 
          ADD mx_date_start bigint, 
          ADD mx_date_end bigint",
          sl$name
          )
        mxDbGetQuery(dbInfo,qAdd)
        # update date start
        qStart = sprintf(
          "UPDATE %s 
          SET mx_date_start = 
          extract(epoch from to_timestamp(octroyé,'YYYY/MM/DD'))",
          sl$name
          )
        mxDbGetQuery(dbInfo,qStart)
        # update date end
        qEnd = sprintf(
          "UPDATE %s 
          SET mx_date_end = 
          extract(epoch from to_timestamp(expire,'YYYY/MM/DD'))",
          sl$name
          )

        mxDbGetQuery(dbInfo,qEnd)
      }

    }



    #
    # Update table layer
    #
    # new entry



    tbl = as.data.frame(stringsAsFactors=FALSE,list(
        country = mxReact$selectCountry,
        layer = sl$name,
        class = sl$class,
        tags = sl$tags,
        editor = mxReact$userId,
        reviewer = mxReact$userId,
        revision = rn,
        validated = TRUE,
        archived = FALSE,
        dateCreated = timeNow,
        dateArchived = as.POSIXct(as.Date(0,origin="1970/01/01")),
        dateModifed = timeNow,
        dateValidated = timeNow,
        meta = mxEncode(as.character(jsonlite::toJSON(sl$meta)))
        )
      )

    if(rn>0){
      # update revision
      mxDbUpdate(
        dbInfo,
        table=tn,
        column="archived",
        idCol="layer",
        id=sl$name,
        value=TRUE
        )
      mxDbUpdate(
        dbInfo,
        table=tn,
        column="dateArchived",
        idCol="layer",
        id=sl$name,
        value=timeNow
        )
    }

    # append or add data.
    mxDbAddData(
      dbInfo,
      data=tbl,
      table=tn
      )

    #
    # Update pgrestapi
    #

    if( mxConfig$hostname != "map-x-full" ){
      if(!exists("remoteInfo"))stop("No remoteInfo found in /settings/settings.R")
      remoteCmd(host="map-x-full",cmd=mxConfig$restartPgRestApi)
    }else{
      system(mxConfig$restartPgRestApi)
    }








    #
    # Update layer list
    #
    mxDebugMsg("invalidate layer list")
    mxReact$layerListUpdate <- runif(1)

    panModal <- mxPanel(
      id="panImportModal",
      title="Import new layer in database.",
      subtitle="Action handler",
      html=p("Importation done. Please check if the layer is available in the views creator.")
      )

    mxUpdateText(id="panelAlert",ui=panModal)

      })
})


#
# Btn refresh
#



observeEvent(input$btnViewsRefresh,{
  if(mxReact$allowViewsCreator){
    mxDebugMsg("Command remote server to restart app")
    if( mxConfig$hostname != "map-x-full" ){
      if(!exists("remoteInfo"))stop("No remoteInfo found in /settings/settings.R")
      remoteCmd("map-x-full",cmd=mxConfig$restartPgRestApi)
    }else{
      system(mxConfig$restartPgRestApi)
    }
    mxReact$layerListUpdate <- runif(1) 
  }
})



#
# Populate layer selection
#
observe({
  if(mxReact$allowViewsCreator){
    # default
    choice <- mxConfig$noData
    # take reactivity on select input

    cntry <- tolower(mxReact$selectCountry)
    # reactivity after updateVector in postgis
    update <- mxReact$layerListUpdate

    mxCatch("Update input: pgrestapi layer list",{
      layers <- vtGetLayers(protocol=mxConfig$protocolVt,port=mxConfig$portVt,grepExpr=paste0("^",cntry,"_"))
      if(!noDataCheck(layers)){
        choice = c(choice,layers)  
      }
      updateSelectInput(session,"selLayer",choices=choice)
      mxReact$layerList = choice
      })
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

        variables <- vtGetColumns(
          protocol=mxConfig$protocolVt,
          table=lay,
          port=mxConfig$portVt,
          exclude=c("geom","gid")
          )$column_name

        if(!noDataCheck(variables)){
          vars = variables
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
    updateSelectInput(session, "selColumnVarToKeep", choices=c(vars,mxConfig$noVariable),selected=vars[1])
  }
})


#
# get selected variable summary, set mxStyle accordingly and update palette choice.
#

observeEvent(input$selColumnVar,{
  if(mxReact$allowViewsCreator){
    lay = input$selLayer
    var = input$selColumnVar
    isolate({
      if(!noDataCheck(lay) && !noDataCheck(var)){
        # extract layer summary from postgres
        layerSummary <- dbGetColumnInfo(dbInfo,lay,var)
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
    })
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
      # save has date state


      #
      # Date handler
      #

      sty$hasDateColumns <- isTRUE(hasDate)

      if(sty$hasDateColumns){
            q <- sprintf("SELECT min(mx_date_start),max(mx_date_end) FROM %s;",sty$layer)
            mxDate <- mxDbGetQuery(dbInfo,q)
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
          sty$companies <- mxDbGetQuery(dbInfo,q)[[ companyColName ]] 
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

      tbl = as.data.frame(stringsAsFactors=FALSE,list(
          id =  randomName(),
          country = mxReact$selectCountry,
          title = input$mapViewTitle,
          class = input$mapViewClass,
          layer = sty$layer,
          editor = mxReact$userId,
          reviever = "",
          revision = 0,
          validated = TRUE,
          archived = FALSE,
          dateCreated = timeNow,
          dataModifed = timeNow,
          dateValidated = timeNow,
          dateArchived = timeNow,
          style = mxEncode(as.character(jsonlite::toJSON(sty)))
          )
        )

      mxDbAddData(
        dbInfo,
        data=tbl,
        table=viewTable
        )

      mxDebugMsg(sprintf("Write style %s in table %s", tbl$id, tbl$layer))
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

