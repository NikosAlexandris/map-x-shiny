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
observeEvent(input$btnLogout,{
mxCatch(title="Logout",{

    reactUser <- reactiveValues()
    mxUpdateValue(id="loginUserEmail",value="")
    mxSetCookie(
      deleteAll=TRUE,
      reloadPage=TRUE
      )
})
})



observeEvent(input$btnNavUser,{

  #
  # Initially logged as guest.
  #

  # if logged as guest or not logged in, display email input and login button.
  # else, log out button. 

btn <- list()
userInfo <- ""

  isNotLogged <- isTRUE(
    reactUser$data$email == mxConfig$mapxGuestEmail ||
      is.null(reactUser$data$email)
    )

  if(isNotLogged){
    # text modal panel subtitle
    txtSubTitle <- "Enter your email to log in or create a new account"
    # ui login 
    loginInput <- div(
      div(id="divEmailInput",
        class="input-group mx-login-group",
        usrInput(
          inputId="loginUserEmail",
          label="Email",
          class="mx-login-input-black form-control"
          ),
        tags$span(
          class="input-group-btn",   
          actionButton(
            inputId="btnSendLoginKey", 
            label=icon("envelope"),
            class="btn-square btn-black mx-hide"
            )
          ) 
        ),
      div(
        tags$input(
          id="loginKey",
          type="text",
          placeholder="Insert the password here",
          class="form-control mx-login-input mx-login-input-black  mx-hide"
          )
        )
      )
  }else{
    txtSubTitle <- "Status"
    sessionDuration <- mxGetSessionDurationHMS(reactUser$data$id)
    
    loginInput <- tags$p(
        sprintf("%1$s is logged as %2$s for %3$s [h] %4$s [min] %5$s [s] ",
          reactUser$data$email,
          reactUser$role$role,
          sessionDuration$H,
          sessionDuration$M,
          sessionDuration$S
          )
        )

    btn <-list(
      actionButton("btnLogout","Log out",icon=icon("sign-out"),class="btn btn-modal")
      )
  }


 panModal <- mxPanel(
      listActionButton=btn,
      defaultButtonText="Cancel",
      addCancelButton=TRUE,
      id="loginCode",
      title="User",
      subtitle=div(id="txtLoginDialog",txtSubTitle), 
      html=loginInput
      )
    # update ui
 output$panelLogin = renderUI(panModal)

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
      msg <- "Enter your email to log in or create a new account."
    }else{
      known <- mxEmailIsKnown(email) 
      msg <- sprintf(
        "<div> 
        Please click on <i class='fa fa-envelope' style='color:black'></i> 
        to %1$s receive a <b>single usage password</b>.",
        ifelse(known,"","create a new account and")
        )
      allowLogin <- TRUE
    }

    mxUiEnable(id="btnSendLoginKey",enable=allowLogin)

    mxUpdateText("txtLoginDialog",HTML(msg))
})
})



#
# Login send login key
#

observeEvent(input$btnSendLoginKey,{
  mxCatch(title="Btn send password event",{
    email <- input$loginUserEmail
    emailIsValid <- mxEmailIsValid(email)
    res <- NULL
    msg <- character(0) 

    if( emailIsValid ){

      mxUpdateValue(
        id="loginKey",
        value=""
        )

      # create the unique secret key
      reactUser$loginSecret <- randomString(
        splitSep="-",
        splitIn=5,
        addLetters=FALSE,
        addLETTERS=TRUE
        )

      mxUpdateText(
        id="txtLoginDialog",
        text="Generate strong password and send it, please wait..."
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

      mxDebugMsg(reactUser$loginSecret)

      if("try-error" %in% class(res)){ 
        msg <- "An error occured, sorry, We can't send you an email right now."

      }else{
        msg <- "An email has been send, please check your email and copy the received password in the box."
       #
       # save the provided address as the input could be change during the interval.
        #
       reactUser$loginUserEmail <- email
       #
       # Update UI
       #
        mxActionButtonState(
          id="btnSendLoginKey",
          disable=TRUE
          )
        mxUiEnable(
          id="loginKey",
          enable=TRUE
          )
        mxUiEnable(
          id="divEmailInput",
          enable=FALSE
          )

        reactUser$loginTimerEndAt <- Sys.time() + mxConfig$loginTimerMinutes*60
      }
    }else{
      msg <- "Email is not valid"
    }

    mxUpdateText(
      id="txtLoginDialog",
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
    if(isOk){
      mxUpdateText(
        id="txtLoginDialog",
        text="Ok!"
        )
      # trigger actual login
      reactUser$loginRequested = runif(1)
      # close the panel
      output$panelLogin <- renderUI(tags$div())
    }else{
      # only one message is returned : 
      #  I think that most probable causes password error are, in this order : 
      # 1. empty password
      # 2. malformed (unwanted characters)
      # 3. wrong password
      # 4. time limit reached.
      if(!k$isEmpty){
        if(k$isOld) msg <- "Time is up, please request a new password."
        if(k$isWrong) msg <- "The password is wrong"
        if(k$isMalformed) msg <- "The password in not valid"
        mxUpdateText(
          id="txtLoginDialog",
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
    mxDebugMsg(sprintf("Login requested for %s",email))
    if(!mxEmailIsValid(email)) return()
    timeStamp <- Sys.time()
    newAccount <- !mxEmailIsKnown(email)
    userTable <- mxConfig$userTableName
    stopifnot(mxEmailIsValid(email))
    # check if the account is "guest"
    isGuest <- isTRUE(email == mxConfig$mapxGuestEmail)

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

    userInfo <- mxDbGetUserInfoList(id=res$id)

    # extract last country
      
    cntry <- mxGetListValue(
      li=userInfo,
      path=c("data","user","cache","last_project")
      )
    
    if(isGuest || noDataCheck(cntry)) cntry <- mxConfig$defaultCountry
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
    reactUser$language <- mxGetListValue(userInfo,c("data","user","preferences","language"))
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
      if(!isTRUE("try-error" %in% class(dat))){
        if(isTRUE(length(dat)>0)){
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
      # 
      # Login as guest
      # 
      # if there is no guest account, create it
      if(!mxEmailIsKnown(mxConfig$mapxGuestEmail)){
        mxDbCreateUser(mxConfig$mapxGuestEmail)  
      }

      reactUser$loginUserEmail <- mxConfig$mapxGuestEmail
      reactUser$loginRequested <- runif(1) 

    }
})
})




#
# Update role
#
observe({
  mxCatch(title="Role attribution",{
    cntry <- reactProject$name
    userInfo <- reactUser$data


    isolate({
      # check if we need to recalc roles
      hasRoles <- !noDataCheck(userInfo$role)
      hasCountry <- !noDataCheck(cntry)
      hasUserInfo <- !noDataCheck(userInfo)

      if(hasRoles || !hasCountry || !hasUserInfo) return()


      #--> userInfo$role <- mxGetMaxRole(
      reactUser$role <- mxGetMaxRole(
        project=cntry,
        userInfo=userInfo
        )
      #
      # Extract role description value
      #
      roleDesc <- reactUser$role$desc
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
      reactUser$allowAnalysisOverlap <- isTRUE("analysis_overlap" %in% access)
      reactUser$allowPolygonOfInterest <- isTRUE("polygon_of_interest" %in% access)
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

    })
})
})


