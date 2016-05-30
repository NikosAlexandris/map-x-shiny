#                             
#  _ __ ___   __ _ _ __   __  __
# | '_ ` _ \ / _` | '_ \  \ \/ /
# | | | | | | (_| | |_) |  >  < 
# |_| |_| |_|\__,_| .__/  /_/\_\
#                 | |           
#                 |_|           
# login and restriction  management


mxReact$userInfo <- list()

#
# Language selection
#
observeEvent(input$selectLanguage,{

  mxCatch(title="Language selection",{
    selLanguage = input$selectLanguage
    if(!noDataCheck(selLanguage)){
      mxReact$selectLanguage = selLanguage
      mxSetCookie(
        cookie=list("mx_language"=selLanguage),
        ) 
    }
}) 
})

#
# Hamdle logout process
#
observeEvent(input$btnNavLogout,{
mxCatch(title="Logout",{
    mxReact$userInfo <- list()
    mxUpdateValue(id="loginUserEmail",value="")
    mxSetCookie(
      deleteAll=TRUE,
      reloadPage=TRUE
      )
})
})

#
# Handle reconnection from cookie stored information
#
observeEvent(input$cookies,{
  tryCatch(title="Reconnection from cookie",{
    dat <- mxDbDecrypt(input$cookies[[mxConfig$defaultCookieName]])
    id <- dat$id
    quer <- sprintf(
      "SELECT email 
      FROM %1$s WHERE 
      id=%2$s AND 
      validated='true' AND 
      hidden='false'",
      mxConfig$userTableName,
      id
      )
    res <- mxDbGetQuery(quer)
    if(!is.null(res) && 'email' %in% names(res) && nrow(res)==1){
      #
      # Request a login
      #
      mxReact$loginUserEmail <- res$email
      mxReact$loginRequested <- runif(1) 
    }else{
      #
      # Enable login panel
      #
      mxUiEnable(
        id="mxPanelLogin",
        enable=TRUE
        )
    }
})
})

#
# Login email input validation 
#
observe({
  #  login validation timing 2-9 ms
  mxCatch(title="Login email validation",{
    email <- input$loginUserEmail
    val <- mxEmailIsValid(email)
    msg <- ""
    allowLogin <- FALSE
    if(!val){
      msg <- "Log in / register"
    }else{
      known <- mxEmailIsKnown(email) 
      if(known){ 
        msg <- "Click on <i class='fa fa-sign-in'></i> to log in."
      }else{
        msg <- "Click on <i class='fa fa-sign-in'></i> to register."
      }
      allowLogin <- TRUE
    }
    mxUiEnable(id="btnLogin",enable=allowLogin)

    mxUpdateText("txtDialogLoginInput",HTML(msg))
})
})





#
# Login modal panel
#
observeEvent(input$btnLogin,{

  mxCatch(title="Login btn event",{
    email <- input$loginUserEmail
    mxReact$loginUserEmail <- email
    # set control timer to 20 minutes
    mxReact$loginTimerEndAt <- Sys.time()-20*60*60*24*365
    userIsLogged <- isTRUE(mxReact$userLogged)
    emailIsKnown <- mxEmailIsKnown(email)
    emailIsValid <- mxEmailIsValid(email)
    #
    # quit if
    #
    if(!emailIsValid) return()
    if(userIsLogged) return()
    #
    # UI generation
    #
    panModal <- mxPanel(
      defaultButtonText="Cancel",
      id="loginCode",
      title=ifelse(emailIsKnown,"Log in","Create a new account"),
      subtitle=HTML(
        sprintf(
          "Click on the button %1$s to %2$s receive a single usage password at </br> <b> %3$s </b> ",
          icon("envelope-o"),
          ifelse(!emailIsKnown,"register and",""),
          email
          )
        ),
      html=tagList(
        div(class="input-group",
          tags$span(class="input-group-btn",   
            actionButton(
              inputId="btnSendLoginKey",
              label="",
              icon=icon("envelope-o"),
              class="btn"
              )
            ),
          tags$input(
            id="loginKey",
            type="text",
            placeholder="Single usage password",
            class="form-control"
            )
          ),
        div(id="txtDialogLogin")
        )
      )
    # update ui
    mxUpdateText(id="panelAlert",ui=panModal)
})
})



#
# Login send login key
#

observeEvent(input$btnSendLoginKey,{
  mxCatch(title="Btn send password event",{
    email <- mxReact$loginUserEmail
    emailIsValid <- mxEmailIsValid(email)
    emailHasChanged <- !identical(input$loginUserEmail,email)

    msg <- character(0) 

    if( emailIsValid && !emailHasChanged ){

      mxUpdateValue(
        id="loginKey",
        value=""
        )

      # create the unique secret key
      mxReact$secret <- randomString(
        n=15,
        splitIn=5,
        addLetters=T,
        splitSep="-"
        )

      mxUpdateText(
        id="txtDialogLogin",
        text="Generate unique password"
        )
      # send mail
      res <- try({
        mxSendMail(
          from=mxConfig$mapxBotEmail,
          to=email,
          body=mxReact$secret,
          subject="Map-x secure login",
          wait=F)
      })

      if("try-error" %in% class(res)){ 
        msg <- "An error occured, sorry, We can't send you an email right now."

      }else{
        msg <- "An email has been send, please check your email and copy the received password in the box above."

        mxActionButtonState(
          id="btnSendLoginKey",
          disable=TRUE
          )
        mxReact$loginTimerEndAt <- Sys.time() + mxConfig$loginTimerMinutes*60
      }
    }else{
      msg <- "Email validation failed"
    }

    mxUpdateText(
      id="txtDialogLogin",
      text=msg
      )
})
})

#
# key status : given login key, login timer and secret, return a
# list containing controls for the key
# 

keyStatus <- reactive({
  mxCatch(title="Key status reactive obj.",{
    key <- input$loginKey
    timer <- mxReact$loginTimerEndAt
    secret <- mxReact$secret

    list(
      isEmpty = isTRUE(is.null(key)) || isTRUE(nchar(key)==0), 
      isMalformed = !isTRUE(grepl("^(\\w{3}-\\w{3}-\\w{3}-\\w{3}-\\w{3})$",key)),
      isWrong = !isTRUE(identical(key,secret)),
      isOld = isTRUE("POSIXct" %in% class(timer) && timer - Sys.time() < 0)
      )
})
})


#
# key validation 
#
observe({
  mxCatch(title="Key validation",{
    k <- keyStatus()
    msg <- ""
    isOk <- !any(sapply(k,isTRUE))
    mxActionButtonState("btnLoginConfirm",disable=!isOk)
    if(isOk){
      mxUpdateText(
        id="txtDialogLogin",
        text="Ok!"
        )
      # trigger actual login
      mxReact$loginRequested = runif(1)
      # close the panel
      mxUpdateText("panelAlert",text="")
    }else{
      # only one message is returned : 
      #  I think that most probable causes password error are, in this order : 
      # 1. empty password
      # 2. malformed (unwanted characters)
      # 3. wrong password
      # 4. time limit reached.
      if(!k$isEmpty){
        if(k$isOld) msg <- "Time is up"
        if(k$isWrong) msg <- "Key is not the good one"
        if(k$isMalformed) msg <- "Key is not valid"
        mxUpdateText(
          id="txtDialogLogin",
          text=HTML(msg)
          )
      }
    }
})
})









#
# create account,set date last visit, create cookie
#
observeEvent(mxReact$loginRequested,{ 
  tryCatch(title="Logic for login process",{
    # set local variables

    email <- mxReact$loginUserEmail
    timeStamp <- Sys.time()
    newAccount <- !mxEmailIsKnown(email)
    userTable <- mxConfig$userTableName
    stopifnot(mxEmailIsValid(email))

    # update ui

    mxUiEnable(
      id="btnNavLogout",
      enable=TRUE
      )
    mxUiEnable(
      id="mxPanelLogin",
      enable=FALSE
      )

    if(newAccount){
      mxDbCreateUser(
        email=email,
        timeStamp=timeStamp
        ) 
    }else{
      mxDebugMsg(sprintf("update last visit for %s",email))
      mxDbUpdate(
        table=userTable,
        column='date_last_visit',
        idCol='email',
        id=email,
        value=timeStamp
        )
    }
    # get id
    res <- mxDbGetQuery(
      sprintf("SELECT id from %1$s WHERE email='%2$s'",
        userTable,
        email
        )
      )
    # if it's empty or not an integer, stop
    stopifnot(isTRUE(is.integer(res$id)))

    # set cookie based on a list
    ck <- mxDbEncrypt(
        list(
          id=res$id
          )
        )
    ck <- list(ck)
    names(ck) <- mxConfig$defaultCookieName
    mxSetCookie(
      cookie = ck,
      expireDays = mxConfig$cookiesExpireDays
      ) 

    # set text
    mxUpdateText(
      id="txtDialogLoginInput",
      text=sprintf("Logged as %s",email)
      )


    userInfo <- mxDbGetUserInfoList(id=res$id)

    # extract last country
    cntry <- mxGetListValue(
      li=userInfo,
      path=c("data","user","preferences","last_project")
      )
    # if no value, get default
    if(noDataCheck(cntry)) cntry <- mxConfig$defaultCountry
    # trigger selectCountry
    # update select input
    updateSelectInput(
      session,
      inputId="selectCountry",
      selected=toupper(cntry)
      )

    # set reactive values
    mxReact$selectCountry <- toupper(cntry)
    mxReact$userInfo <- userInfo 
    mxReact$userLogged <- TRUE
    mxReact$allowCountry <- TRUE
})
})

#
# Update role
#
observeEvent(mxReact$selectCountry,{
  cntry <- mxReact$selectCountry
  userInfo <- mxReact$userInfo
  # get roles
  if(noDataCheck(cntry)) return()

  userInfo$role <- mxGetMaxRole(
    project=cntry,
    userInfo=userInfo
    )

  #NOTE: order is important
  access <- mxGetListValue(userInfo,c("role","desc","access"))
  mxReact$allowStoryCreator <- isTRUE("storymap_creator" %in% access)
  mxReact$allowStoryReader <-  isTRUE("storymap" %in% access)
  mxReact$allowViewsCreator <-isTRUE("view_creator" %in% access)
  mxReact$allowDataUpload <- isTRUE("data_upload" %in% access)
  mxReact$allowToolbox <- isTRUE("tools" %in% access)
  mxReact$allowMap <- isTRUE("map" %in% access)
  mxReact$allowAdmin <- isTRUE("admin" %in% access)

  mxReact$userInfo <- userInfo 
})

observeEvent(mxReact$userInfo,{
  usr <- mxReact$userInfo$role$desc
  if(length(usr)<1) return();

  if('data_upload' %in% usr$access){
    updateSelectInput(session,
      inputId="selNewLayerVisibility",
      choices=usr$publish
      )
  }
  if('view_creator' %in% usr$access){
    updateSelectInput(session,
      inputId="selNewViewVisibility",
      choices=usr$publish
      )
  }
  if('storymap_creator' %in% usr$access){
    updateSelectInput(session,
      inputId="selStoryVisibility",
      choices=usr$publish
      )
  }
})

observeEvent(mxReact$mapPanelMode,{
  enable <- FALSE
  if(
    mxReact$allowViewsCreator &&
      isTRUE(mxReact$mapPanelMode == "mapViewsCreator")
    ){
    enable <- TRUE
  }
  mxReact$enableViewsCreator <- enable
  enable = FALSE
  if(
    mxReact$allowViewsCreator &&
      isTRUE(mxReact$mapPanelMode == "mapViewsToolbox")
    ){
    enable <- TRUE
  }
  mxReact$enableToolbox <- enable


})




