
#
# Parse meta from input
#
observe({
  out = list()
  try(silent=T,{
    # Silent because this function can very likely return an error 
    out <- mxParseListFromText(input$txtNewLayerMeta)
})
  reactMap$newLayerMeta = out
})


# new layer name validation

observe({
  if(reactUser$allowUpload && reactUi$panelMode == "toolBox" ){
    err = character(0)
    info = character(0)
    out  = character(0)
    valid = FALSE
    msgList = character(0)


    #
    # Layer name warning
    #
    cty <- reactProject$name
    #yea <- input$selNewLayerYear
    cla <- input$selNewLayerClass
    sub <- subPunct(input$txtNewLayerTags)
    met <- reactMap$newLayerMeta

    #newLayerName <- tolower( paste0(cty,"__",yea,"__",cla,"__",sub))
    newLayerName <- tolower( paste0(cty,"__",cla,"__",sub))

    exist <- mxTextValidation(
      textToTest = newLayerName,
      existingTexts = reactMap$layerList,
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

    reactMap$newLayerName <- ifelse(valid,newLayerName,"")
  }
})


#
#  FILE HANDLER : VALIDATION AND PSQL 
#


observeEvent(input$fileNewLayer,{

  if(reactUser$allowViewsCreator){

    met <- reactMap$newLayerMeta
    src <- input$fileNewLayer$datapath
    nam <- reactMap$newLayerName 
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

    # expected proj4 string for epsg 4326
    expectedProj4 <- "'+proj=longlat +datum=WGS84 +no_defs '"

    # query the layer's srs
    layerSRS <- gdalsrsinfo(src, o = "proj4")

    # compare with what is expected
    projOk = isTRUE( expectedProj4 == layerSRS )

    if(!projOk){
      msg <- "Error before importation : srid is not '4326'"
      mxUpdateText("outLayerFileMsg",msg)
      return()
    }

    #
    # Return summary list
    #

    reactMap$newLayerSummary = list(
      class = cla,
      tags = tgs,
      name = nam,
      meta = met,
      srid = ifelse(projOk,"4326","nodata"),
      file = src
      )

  }

})



observeEvent(reactMap$newLayerSummary,{

  sl <- reactMap$newLayerSummary 
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
    sl <- reactMap$newLayerSummary 
    # append in table
    ap <- FALSE
    # table name
    tn <- mxConfig$layersTableName
    # table list
    te <- mxDbExistsTable(tn)
    le <- mxDbExistsTable(sl$name)
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
      res <- mxDbGetQuery(q)$revision
      # replace revision number if needed
      if(isTRUE(is.numeric(res))){
        rn <- res + 1
      }
    }
    #
    # Save into layer table
    #
    mxDbAddGeoJSON(
      geojsonPath=sl$file,
      tableName=sl$name,
      archivePrefix = mxConfig$prefixArchiveLayer
      )
    #
    # get existing columns
    #
    cols <- mxDbGetColumnsNames(sl$name)

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
        mxDbGetQuery(qAdd)
        # update date start
        qStart = sprintf(
          "UPDATE %s 
          SET mx_date_start = 
          extract(epoch from to_timestamp(octroyé,'YYYY/MM/DD'))",
          sl$name
          )
        mxDbGetQuery(qStart)
        # update date end
        qEnd = sprintf(
          "UPDATE %s 
          SET mx_date_end = 
          extract(epoch from to_timestamp(expire,'YYYY/MM/DD'))",
          sl$name
          )

        mxDbGetQuery(qEnd)
      }

    }



    #
    # Update table layer
    #
    # new entry

 # overwrite
    mxDbGetQuery(sprintf("DELETE FROM %1$s WHERE \"layer\"=='%2$s'",
      tn,
      sl$name))

    rn <- mxDbGetQuery(sprintf("SELECT revision from mx_layers where \"layer\"='%1$s' ",
        sl$name
        ))$revision

    if(noDataCheck(rn)) rn = 0

    tbl<- list(
        country = reactProject$name,
        layer = sl$name,
        class = sl$class,
        tags = sl$tags,
        editor = reactUser$data$id,
        reviewer = reactUser$data$id,
        revision = rn,
        validated = TRUE,
        archived = FALSE,
        date_created = timeNow,
        date_archived = as.POSIXct(as.Date(0,origin="1970/01/01")),
        date_modified = timeNow,
        date_validated = timeNow,
        meta = mxToJsonForDb(sl$meta),
        visibility = mxToJsonForDb(input$selNewLayerVisibility)
        )

   

    # append or add data.
    mxDbAddRow(
      data=tbl,
      table=tn
      )

    #
    # Update layer list
    #
    mxDebugMsg("invalidate layer list")
    reactMap$layerListUpdate <- runif(1)

    panModal <- mxPanel(
      id="panImportModal",
      title="Import new layer in database.",
      subtitle="Action handler",
      html=p("Importation done. Please check if the layer is available in the views creator.")
      )

    mxUpdateText(id="panelAlert",ui=panModal)

      })
})



