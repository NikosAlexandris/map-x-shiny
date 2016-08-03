



#' Load external ui file value in shiny app
#'
#' Shortcut to load external shiny ui file
#'
#' @param path Path to the file
#' @export
loadUi<-function(path){
  source(path,local=TRUE)$value
}




#' Password input
#'
#' Create a password input.
#' 
#' @param inputId Input id
#' @param label Label to display
#' @export
pwdInput <- function(inputId, label) {
    tagList(
    tags$input(id = inputId,placeholder=label,class="mx-login-input",type="password", value="")
    )
}

#' User name input
#' 
#' Create a username input
#' 
#' @param inputId Input id
#' @param label Label to display
#' @export
usrInput <- function(inputId, label,class="form-control") {
    tags$input(
      id = inputId, 
      placeholder=label,
      class=paste("mx-login-input",class),
      value="",
      autocomplete="off",
      autocorrect="off", 
      autocapitalize="off",
      spellcheck="false"
      )
}

#' Create a modal panel
#'
#' Create a modal panel with some options as custom button, close button, html content. 
#'
#' @param id Panel id
#' @param title Panel title
#' @param subtitle Panel subtitle
#' @param html HTML content of the panel, main text
#' @param listActionButton If FALSE, hide buttons. If NULL, display default close panel button, with text given in defaultButtonText. If list of buttons, list of button.
#' @param defaultButtonText Text of the default button if listActionButton is NULL and not FALSE
#' @param style Additional CSS style for the panel 
#' @param class Additional class for the panel
#' @param hideCloseButton Boolean. Hide the close panel button
#' @param draggable Boolean. Set the panel as draggable
#' @export
mxPanel<- function(
  id="default",
  title=NULL,
  subtitle=NULL,
  html=NULL,
  listActionButton=NULL,
  background=TRUE,
  addCancelButton=FALSE,
  addOnClickClose=TRUE,
  defaultButtonText="OK",
  style=NULL,
  class=NULL,
  hideCloseButton=FALSE,
  draggable=TRUE,
  fixed=TRUE,
  defaultTextHeight=150
  ){ 

  classModal <- "panel-modal"
  rand <- randomString(splitIn=1,addLetters=T)

  idBack <- paste(id,rand,"background",sep="_")
  idContent <- paste(id,rand,"content",sep="_")
  jsHide <- paste0("$('#",idContent,"').toggle();$('#",idBack,"').toggle()")
  

  if(!is.null(listActionButton) && isTRUE(addOnClickClose)){
    listActionButton <- lapply(
      listActionButton,
      function(x){
        x$attribs$onclick<-jsHide
        return(x)
      }
      )
  }  
  
  # If NULL Set default button action to "close" panel, with custom text

  if(is.null(listActionButton)){
    listActionButton=list(
    tags$button(onclick=jsHide,defaultButtonText,class="btn btn-modal")
    )
  }

  if(addCancelButton){
  listActionButton <- tagList(
    listActionButton, 
    tags$button(onclick=jsHide,"Cancel",class="btn btn-modal")
    )
  }

  # if explicit FALSE is given, remove modal button. 
  if(isTRUE(is.logical(listActionButton) && !isTRUE(listActionButton)))listActionButton=NULL
  # close button handling
  if(hideCloseButton){
    closeButton=NULL
  }else{
    closeButton=a(href="#", onclick=jsHide,style="float:right;color:black",icon('times'))
  }

  if(background){
    backg <- div(id=idBack,class=paste("panel-modal-background"))
  }else{
    backg <- character(0)
  }



  if(draggable){
    scr <- tags$script(sprintf('
        $("#%1$s").draggable({ 
          cancel: ".panel-modal-text,.panel-modal-title,.panel-modal-subtitle"
        }).resizable();
        ',idContent))
  }else{
    scr = ""
  }

  if(fixed){
    style = paste("position:fixed",style)
  }else{
    style = paste("position:absolute",style)
  }

  tagList( 
    backg,
    div( 
      id=idContent,
      class=paste(class,classModal,"panel-modal-content col-xs-12 col-sm-6 col-sm-offset-3 col-lg-4 col-lg-offset-4"),
      style=style,
      closeButton,
      div(class=paste("panel-modal-head"),  
        div(class=paste("panel-modal-title"),title)
        ),
      div(class=paste("panel-modal-subtitle"),subtitle),
      div(class="panel-modal-text-container",
      div(class=paste("panel-modal-text"),
        div(class="no-scrollbar-container",
          div(class="no-scrollbar-content mx-panel-400",
              html
            )
          )
        )
      ),
      div(class=paste('panel-modal-buttons'),
        listActionButton
        )
      ),
    scr
    ) 
}
#' Alert panel
#'
#' Create an alert panel. This panel could be send to an output object from a reactive context. 
#'
#' @param title Title of the alert. Should be "error", "warning" or "message"
#' @param subtitle Subtitle of the alert
#' @param message html or text message for the alert
#' @param listActionButtons List of action button for the panel
#' @export
mxPanelAlert <- function(title=c("error","warning","message"),subtitle=NULL,message=NULL,listActionButton=NULL,...){ 
  title = match.arg(title)
  switch(title,
    'error'={title=h2(icon("frown-o"))},
    'warning'={title=h2(icon("frown-o"))},
    'message'={title=h2(icon("info-circle"))} 
    )
  mxPanel(class="panel-overall panel-fixed",title=title,subtitle=subtitle,html=message,listActionButton=listActionButton,style="position:fixed;top:100px",...)
}



#' Create a bootstrap accordion 
#'
#' Create a bootstrap accordion element, based on a named list.
#'
#' @param id Accordion group ID
#' @param style Additional style. 
#' @param show Vector of item number. Collapse all item except those in this list. E.g. c(1,5) will open items 1 and 5 by default. 
#' @param itemList Nested named list of items, containing title and content items. E.g. list("foo"=list("title"="foo","content"="bar"))
#' @examples 
#' mxAccordionGroup(id='superTest',
#'  itemList=list(
#'    'a'=list('title'='superTitle',content='acontent'),
#'    'b'=list('title'='bTitle',content='bContent'))
#'  )
#' @export
mxAccordionGroup <- function(id,style=NULL,show=NULL,itemList){
  if(is.null(style)) style <- ""
  cnt=0
  contentList<-lapply(itemList,function(x){
    cnt<<-cnt+1
    ref<-paste0(subPunct(id,'_'),cnt)
    showItem<-ifelse(cnt %in% show,'collapse.in','collapse')
    stopifnot(is.list(x) || !noDataCheck(x$title) || !noDataCheck(x$content))

    onShow <- ifelse(noDataCheck(x$onShow),"",x$onShow)
    onHide <- ifelse(noDataCheck(x$onHide),"",x$onHide)

    if(is.null(x$condition)) x$condition="true"
    div(
      style=style,
      class=paste("mx-accordion-item",x$class),
      `data-display-if`=x$condition,
      div(
        class="mx-accordion-header",
        tags$span(
          class="mx-accordion-title",
          tags$a('data-toggle'="collapse", 
            'data-parent'=paste0('#',id),
            href=paste0("#",ref),x$title
            )
          )
        ),
      div(
        id=ref,
        class=paste("mx-accordion-collapse",showItem
          ),
        div(
          class="mx-accordion-content",
          x$content
          ),
        tags$script(
          sprintf('
            $("#%1$s").on("show.bs.collapse", function () {
              %2$s
            }).on("hide.bs.collapse", function () {
            %3$s
    }); 
            '
            , ref
            , onShow
            , onHide
            )
          )
        )
      )
})

  return(div(class="mx-accordion-group",id=id,
      contentList
      )
    )
}
#' Custom file input 
#'
#' Default shiny fileInput has no option for customisation. This function allows to fully customize file input using the label tag.
#'
#' @param inputId id of the file input
#' @param label Label for the input
#' @param fileAccept List of accepted file type. Could be extension.
#' @param multiple  Boolean. Allow multiple file to be choosen. Doesn't work on all client.
#' @export
mxFileInput<-function (inputId, label, fileAccept=NULL, multiple=FALSE){
  inputTag<-tags$input(
    type='file',
    class='upload',
    accept=paste(fileAccept,collapse=','),
    id=inputId,
    name=inputId)
  if(multiple) inputTag$attribs$multiple='multiple'
  spanTag <- tags$span(label)
  inputClass <- tags$label(
    class=c('btn-browse btn btn-default'),
    id=inputId,
    spanTag,
    inputTag
    )
  tagList(inputClass,
    tags$div(id = paste(inputId,"_progress", sep = ""), 
      class = "progress progress-striped active shiny-file-input-progress",
      tags$div(class = "progress-bar"), tags$label()))
}


#' Custom select input
#'
#' Custom select input without label.
#'
#' @param inputId Element id
#' @param choices List of options
#' @param select Value selected by default
#' @export
mxSelectInput<-function(inputId,choices=NULL,selected=NULL){
  opt <- NULL
  if(!noDataCheck(choices)){
    if(noDataCheck(selected))selected=choices[1]
    opt <- HTML(sprintf("<option value=%s>%s</option>",choices,choices))
  }
  tagList(
    div(class="form-control form-group shiny-input-container mx-select-input-container",
        tags$select(id=inputId,class="form-control shiny-bound-input  mx-select-input",opt)
      )
    )
}

#' Set ioRange slider for opacity
#'
#' Return a div than contain a slider input instantiated with ionRangeSlider for view opacity
#' 
#' @param id Id of the slider
#' @param opacity Default opacity
#' @export
mxSliderOpacity <- function(id,opacity){
  if(noDataCheck(opacity))opacity=1
  tagList(
    tags$div(class="slider-date-container",
      tags$div(type="text",id=sprintf("slider-opacity-for-%s",id)),
      tags$script(sprintf(
          "
          $slider = $('#slider-opacity-for-%1$s');
          $slider.ionRangeSlider({
            min: 0,
            max: 1,
            from: %2$s,
            step:0.1,
            onChange: function (data) {
              setOpacityForId('%1$s',data.from)
            }
          });",
          id,
          opacity
          )
        )
      )
    ) 
}




#' Set ioRange slider for time slider
#'
#' Return a div than contain a slider input instantiated with ionRangeSlider for view time slider range.
#' 
#' @param id Id of the slider
#' @param min Minimum js unix date in milisecond 
#' @param max Maxmimum js unix date in milisecond 
#' @param lay Layer name
#' @export 
mxTimeSliderRange <-function(id,min,max,lay){
  tagList(
    tags$div(class="slider-date-container",
      tags$input(type="text",id=sprintf("slider-range-for-%s",id)),
      tags$script(sprintf(
          "
          $slider = $('#slider-range-for-%3$s');
          $slider.ionRangeSlider({
            type: 'double',
            min: %1$s,
            max: %2$s,
            from: %1$s,
            to: %2$s,
            step:1000*60*60*24, // 1 day
            prettify: function (num) {
              var m = moment(num)
              return m.format('YYYY-MM-DD');
            },
            onChange: function (data) {
              mxSetRange('%3$s',data.from/1000,data.to/1000,'%4$s')
            }
          });",
          min,
          max,
          id,
          lay
          )
        )
      )
    ) 
}

#' Set ioRange slider for time slider
#'
#' Return a div than contain a slider input instantiated with ionRangeSlider for view time slider.
#'  
#' @param id Id of the slider
#' @param min Minimum js unix date in milisecond 
#' @param max Maxmimum js unix date in milisecond 
#' @param lay Layer name
#' @export 
mxTimeSlider <- function(id,min,max,lay){
  if(noDataCheck(min))min=0
  if(noDataCheck(max))min=1
  tagList(
    tags$div(class="slider-date-container",
      tags$div(type="text",id=sprintf("slider-for-%s",id)),
      tags$script(sprintf(
          "
          $slider = $('#slider-for-%3$s');
          $slider.ionRangeSlider({
            min: %1$s,
            max: %2$s,
            from: %1$s,
            to: %2$s,
            step:1000*60*60*24, // 1 day
            prettify: function (num) {
              var m = moment(num)
              return m.format('YYYY-MM-DD');
            },
            onChange: function (data) {
              mxFilterDate('%3$s',data.from/1000,'%4$s')
            }
          });",
          min,
          max,
          id,
          lay
          )
        )
      )
    ) 
}


#' Create html list of available views
#'
#' get a list of views and return a HTML shiny checkbox input.
#'
#' @param views List of available views
#' @export
mxMakeViews<-function(views){
  session <- shiny:::getDefaultReactiveDomain()
  checkListOut <- p("No view found.")
v <- views
cl <- mxConfig$class
  if(!is.null(v)){
    # NOTE : what is this ?
    cl = data.frame(n=names(cl),id=as.character(cl),stringsAsFactors=FALSE)
    clUn = unique(sapply(v,function(x)x$class))
    viewsList = list()
    for(i in names(v)){
      title <- v[[i]]$title 
      class <- v[[i]]$class
      className <- cl[cl$id == class,'n']
      viewId <- as.list(i)
      names(viewId) <- title
      other <- viewsList[[className]]
      if(is.null(other)){
        viewsList[[className]] <- viewId
      }else{
        viewsList[[className]] <- c(viewId,other)
      }
    }
    id = "viewsFromMenu"
    checkList = tagList()
    for(i in names(viewsList)){
      items <- viewsList[[i]]
      checkList <- tagList(checkList,tags$span(class="map-views-class",i))
      for(j in names(items)){

        # set item id text
        it <- items[j]
        # id of the view
        itId <- as.character(it)
        # view data
        dat <- v[[itId]]  
        # view name
        itName <- names(it)
        # id for checkbox option
        itIdCheckOption <- sprintf('checkbox_opt_%s',itId)
        # id for label
        itIdLabel <- sprintf('label_for_%s',itId)
        # id for checkbox option label
        itIdCheckOptionLabel <- sprintf('checkbox_opt_label_%s',itId)
        # id foc checkbox option panel
        itIdCheckOptionPanel <- sprintf('checkbox_opt_panel_%s',itId)
        # id for company filter select input
        itIdFilterCompany <- sprintf('select_filter_for_%s',itId)
        # id for companis report
        itIdBtnReport <- sprintf('btn_show_report_for_%s',itId)

        # visibility
        viewVisibility <- subPunct(dat$visibility)
        # set icons
        visibilityIcon <- switch(viewVisibility,
          "public"="check",
          "editor"="legal",
          "lock"
          ) %>% 
        icon(.,class="mx-view-icon") %>%
        span(
          "onClick" = sprintf("mxEditView('%s')",itId),
          "title" = sprintf(
            "Visibility: %1$s\nEditor: %2$s\nValidated: %3$s"
            ,viewVisibility
            ,dat$editor
            ,dat$validated
            ),
          .
          ) 
        # Description 
        infoIcon <- icon("info-circle",class="mx-view-icon") %>%
          span(
          "onClick" = sprintf("mxRequestMeta('%s')",itId),
          "title" = "View meta data",
          .
          )
        # Sliders
        
        sliderIcon <- icon("sliders",class="mx-view-icon") %>%
          span(
            "onClick" = sprintf("classToggle('%s')",itIdCheckOptionPanel),
            title="View tools"
            )

        # Auto zoom
         zoomIcon <- icon("search-plus",class="mx-view-icon") %>%
           span(
             "onClick" = sprintf("mxRequestZoom('%s')",dat$layer),
             "title"="Zoom to extent"
             )
        #
        # check if time slider or filter should be shown
        #
        hasDate <- isTRUE(dat$style$hasDateColumns)
        hasCompany <- isTRUE(dat$style$hasCompanyColumn)
        
  

        # layer name
        layerName <- dat$layer

        #
        # create time slider
        #
        if(hasDate){
          timeSlider <- mxTimeSlider(
            id=itId,
            min=as.numeric(as.POSIXct(dat$style$dateMin))*1000,
            max=as.numeric(as.POSIXct(dat$style$dateMax))*1000,
            lay=v[[itId]]$layer
            )
          timeSliderRange <- mxTimeSliderRange(
            id=itId,
            min=as.numeric(as.POSIXct(dat$style$dateMin))*1000,
            max=as.numeric(as.POSIXct(dat$style$dateMax))*1000,
            lay=v[[itId]]$layer
            )
        }else{
          timeSlider <- tags$div()
          timeSliderRange <- tags$div()
        }
        # 
        # create custom selectize input for company
        #
        if(hasCompany){
          # which field contains company names ?
          fieldSelected <- "parties"

          companies <- unlist(dat$style$companies)
        #  updateSelectizeInput(session,
            #itIdFilterCompany,
            #choices = companies,
            #server=TRUE
            #)

          # create selectize js code

          filterSelect <- selectizeInput(
            inputId=itIdFilterCompany, 
            label="", 
            choices = companies,
            options = list(
              placeholder = 'Please select a company',
              onInitialize = I(
                sprintf('
                  function() {
                    this.setValue("");
                    this.on("change",function(){
                      val = this.getValue(); 
                      mxSetFilter("%1$s","%2$s","%3$s",val)
                      });
                  }
                  ',
                  dat$layer,#1
                  itId,#2
                  fieldSelected#3
                  )
                )
              )
            )

      }else{
        filterSelect <- tags$div()
      }
      #
      # report button UGLY AAaah, sorry.
      #
      reportButton <- tagList(
        if(hasCompany){
          tagList(
        tags$button(
          id=itIdBtnReport,
          class="btn btn-default btn-sm mx-layer-button mx-hide",
          onclick="classToggle('infoBox')",
          "Company report"),
        tags$script(
          #sprintf("
            #$('#%1$s').on('click',function(){
              #mxConfig.mapInfoBox.toggle(700,true);
             #var trigger = Math.random();
          #Shiny.onInputChange('tenke',trigger); 
        #})",
            #itIdBtnReport
            #),
          sprintf("
            $('#%1$s').change(function(){
              if( this.value == 'TENKE FUNGURUME MINING' ){
                $('#%2$s').removeClass('mx-hide');
              }else{
                $('#%2$s').addClass('mx-hide');
              }
        })",
            itIdFilterCompany,
            itIdBtnReport
            )
          )
        )
        }
        )

      requestMetaBtn <- tags$button(
        class="btn btn-default btn-sm mx-layer-button",
        onclick=sprintf("mxRequestMeta('%1$s')",
          dat$id
          ),
        icon("info")
        )

 
      viewButtons <- tagList(
        div(class="mx-view-button-group",
        #requestMetaBtn,
        #downloadBtn,
        reportButton
        )
        )


      # toggle option panel for this view . TODO: use bootstrap for this
      toggleOptions <- sprintf("toggleOptions('%s','%s','%s')",itId,itIdCheckOptionLabel,itIdCheckOptionPanel)
      # set on hover previre for this view
      # previewTimeOut <- tags$script(sprintf("vtPreviewHandler('%1$s','%2$s','%3$s')",itIdLabel,itId,500))
      previewTimeOut <- ""
      #
      # View's checkbox input and label
      #
      checkView <- tags$label(
        id = itIdLabel,
        draggable= TRUE,
        tags$input(
          type = "checkbox",
          class = "mx-hide",
          name = id,
          value = itId
          ),
        tags$span(
          class="map-view-label",
          "title"= sprintf("%s (%s)",dat$title,dat$layer),
          mxShort(itName,30)
          )
        )

      #
      # View icons / options
      #
      checkIcon <- tags$span(class="mx-view-icons-container",
        tags$span(class="mx-view-icons-content",
         visibilityIcon,
         infoIcon,
         sliderIcon,
         zoomIcon
        )
        )
      #
      # View drag script
      #
      checkDragScript <- tags$script(
        sprintf("
          /* Add drag handler*/
            document.getElementById('%1$s')
          .addEventListener('dragstart',function(e){
            var currentCoord = document.getElementById('txtLiveCoordinate').innerHTML,
            r = String.fromCharCode(13),
            viewId = '%2$s',
            viewTitle = '%3$s',
            stringStart = '@view_start( '+viewTitle+' ; '+viewId+' ; '+currentCoord+' )', 
            stringEnd = '@view_end',
            res = stringStart + r + r + stringEnd + r + r;
            e.dataTransfer.setData('text', res);
          })",
          itIdLabel,
          dat$id,
          dat$title
          )
        )
      #
      # View options panel
      #
      checkOptions <- tags$div(class="map-views-item-options mx-hide",id=itIdCheckOptionPanel,
            mxSliderOpacity(
              itId,
              v[[itId]]$style$opacity
              ),
            timeSlider,
            timeSliderRange,
            filterSelect,
            viewButtons,
            previewTimeOut
          )
      #
      # View item
      #
      checkItem <- tags$div(
        class="map-view-item",
        checkView,
        checkIcon,
        checkOptions,
        checkDragScript
        )

     
        checkList <- tagList(checkList,checkItem)
    }
  }
  checkListOut <- tagList(
    div(id=id,class="form-group shiny-input-checkboxgroup shiny-input-container",
      div(class="shiny-options-group",
        checkList
        )
      )
    )
}
  
  return(checkListOut)
  }



mxButtonToggle <- function(inputId=NULL,title="Toggle",contentChecked="\\f06e",contentUnchecked="\\f070",class="btn btn-default"){

  name <- sprintf(
    "check_%1$s"
    , inputId
    )

  classLabel <- sprintf(
    "mx-check-%1$s"
    , inputId
    )

tags$div(
  title=title,
  tags$input(
    type="checkbox",
    style="display:none",
    name=name,
    id=inputId,
    value="attributes"
    ),
  tags$label(
    class=paste(paste(class,collapse=" "),classLabel),
    `for`=inputId
  ),
  tags$style(
    sprintf(
      "#%1$s ~ .%2$s:before {
      font-family:fontawesome;
      content:\"%3$s\";}
       #%1$s:checked ~.%2$s:before {
      font-family:fontawesome;
      content:\"%4$s\";}"
      , inputId
      , classLabel
      , contentChecked
      , contentUnchecked
      )
    )
  )


}

