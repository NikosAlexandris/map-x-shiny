#                             
#  _ __ ___   __ _ _ __   __  __
# | '_ ` _ \ / _` | '_ \  \ \/ /
# | | | | | | (_| | |_) |  >  < 
# |_| |_| |_|\__,_| .__/  /_/\_\
#                 | |           
#                 |_|           
# login and restriction  management


reactUser$data <- list()

#
# Language selection
#
observeEvent(input$selectLanguage,{

  mxCatch(title="Language selection",{
    selLanguage = input$selectLanguage
    if(!noDataCheck(selLanguage)){
      reactUser$language = selLanguage
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
    reactUser$data <- list()
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
  mxCatch(title="Reconnection from cookie",{

    dat <- NULL
    res <- NULL

    if(isTRUE(length(input$cookies)>0)){
      dat <- mxDbDecrypt(input$cookies[[mxConfig$defaultCookieName]])

      if(isTRUE(lenght(dat)>0)){
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
      }
    }

    if(!is.null(res) && 'email' %in% names(res) && nrow(res)==1){
      #
      # Request a login
      #
      reactUser$loginUserEmail <- res$email
      reactUser$loginRequested <- runif(1) 
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
    reactUser$loginUserEmail <- email
    # set control timer to 20 minutes
    reactUser$loginTimerEndAt <- Sys.time()-20*60*60*24*365
    userIsLogged <- isTRUE(reactUser$isLogged)
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
    email <- reactUser$loginUserEmail
    emailIsValid <- mxEmailIsValid(email)
    emailHasChanged <- !identical(input$loginUserEmail,email)

    msg <- character(0) 

    if( emailIsValid && !emailHasChanged ){

      mxUpdateValue(
        id="loginKey",
        value=""
        )

      # create the unique secret key
      reactUser$loginSecret <- randomString(
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
          body=reactUser$loginSecret,
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
        reactUser$loginTimerEndAt <- Sys.time() + mxConfig$loginTimerMinutes*60
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
    timer <- reactUser$loginTimerEndAt
    secret <- reactUser$loginSecret

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
      reactUser$loginRequested = runif(1)
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
observeEvent(reactUser$loginRequested,{ 
  tryCatch(title="Logic for login process",{
    # set local variables

    email <- reactUser$loginUserEmail
    timeStamp <- Sys.time()
    newAccount <- !mxEmailIsKnown(email)
    userTable <- mxConfig$userTableName
    stopifnot(mxEmailIsValid(email))

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

   #
   # update ui
   #
    mxUpdateText(
      id="txtDialogLoginInput",
      text=sprintf("Logged as %s",email)
      )
    mxUiEnable(
      id="btnNavLogout",
      enable=TRUE
      )
    mxUiEnable(
      id="mxPanelLogin",
      enable=FALSE
      )

    userInfo <- mxDbGetUserInfoList(id=res$id)

    # extract last country
    cntry <- mxGetListValue(
      li=userInfo,
      path=c("data","user","cache","last_project")
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
    reactProject$name <- toupper(cntry)
    reactUser$data <- userInfo 
    reactUser$isLogged <- TRUE
    reactUser$allowCountry <- TRUE
    #
    # 
    #
    reactUser$language <- mxGetListValue(userInfo,c("data","user","preferences","language"))
})
})

#
# Update role
#
observeEvent(reactProject$name,{
  cntry <- reactProject$name
  userInfo <- reactUser$data
  # get roles
  if(noDataCheck(cntry)) return()



  userInfo$role <- mxGetMaxRole(
    project=cntry,
    userInfo=userInfo
    )

  
  roleDesc <- mxGetListValue(userInfo,c("role","desc"))
  access <- roleDesc$access
  profile <- roleDesc$profile
  edit <- roleDesc$edit
  publish <- roleDesc$publish

  #
  # Set user access
  #
  
  reactUser$allowStoryCreator <- isTRUE("storymap_creator" %in% access)
  reactUser$allowStoryReader <-  isTRUE("storymap" %in% access)
  reactUser$allowViewsCreator <-isTRUE("view_creator" %in% access)
  reactUser$allowUpload <- isTRUE("data_upload" %in% access)
  reactUser$allowToolbox <- isTRUE("tools" %in% access)
  reactUser$allowMap <- isTRUE("map" %in% access)
  reactUser$allowAdmin <- isTRUE("admin" %in% access)
  reactUser$allowProfile <- isTRUE("profile" %in% access)

  #
  # Update select publishing / editing target
  #

if("data_upload" %in% access){
    updateSelectInput(session,
      inputId="selNewLayerVisibility",
      choices=publish
      )
  }
  if("view_creator" %in% access){
    updateSelectInput(session,
      inputId="selNewViewVisibility",
      choices=publish
      )
  }
  if("storymap_creator" %in% access){
    updateSelectInput(session,
      inputId="selStoryVisibility",
      choices=publish
      )
  }


#  if("profile" %in% access){
    #edit <- profile
    ## user to edit :
    #users <- mxDbGetUserInfoByRole(
      #project = cntry,
      #selfId = userInfo$id,
      #roles = profile
      #)
    
  #}

  reactUser$data <- userInfo 

})

#observeEvent(reactUser$data,{
  #usr <- reactUser$data$role$desc
  #if(length(usr)<1) return();

  #})

observeEvent(reactUi$panelMode,{
  enable <- FALSE
  if(
    reactUser$allowViewsCreator &&
      isTRUE(reactUi$panelMode == "mapViewsCreator")
    ){
    enable <- TRUE
  }
  reactUser$allowViewsCreator <- enable
  enable = FALSE
  if(
    reactUser$allowViewsCreator &&
      isTRUE(reactUi$panelMode == "mapViewsToolbox")
    ){
    enable <- TRUE
  }
  reactUser$allowToolbox <- enable


})




