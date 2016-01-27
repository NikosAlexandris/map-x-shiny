#                             
#  _ __ ___   __ _ _ __   __  __
# | '_ ` _ \ / _` | '_ \  \ \/ /
# | | | | | | (_| | |_) |  >  < 
# |_| |_| |_|\__,_| .__/  /_/\_\
#                 | |           
#                 |_|           
# login and restriction  management

#
# initialise  session when document is ready
#
observeEvent(input$documentIsReady,{
  tempSecret <-  mxCreateSecret()
  mxSetCookie(cookie=list(t=session$token,s=tempSecret))
  mxReact$tempSecret <- tempSecret
  mxReact$userLogged <- FALSE
  mxReact$userRole <- character(0)
  mxReact$userName <- character(0)
  mxReact$userId <- integer(0)
  mxReact$sessionToken <- session$token
})



# Language selection
observeEvent(input$selectLanguage,{
  selLanguage = input$selectLanguage
  if(!noDataCheck(selLanguage)){
    mxReact$selectLanguage = selLanguage
    mxSetCookie(
      cookie=list(lang=selLanguage)
      )
  } 
})

# if the user press the login button and is not yet logged, write a cookie
# the cookie will be read again server side.
observeEvent(input$btnLogin,{
  if (mxReact$userLogged == FALSE) {
    lUser <- input$loginUser
    lKey <- input$loginKey
    if (!noDataCheck(lUser) && !noDataCheck(lKey)) {
      if (input$btnLogin > 0) {
        lSec <- mxCreateSecret() # send a temp secret, only for this request.
        res <- list(
          l = lUser,
          k = lKey,
          s = lSec
          )
        # NOTE: save the secret in reactive elemement
        mxReact$tempSecret <- lSec
        mxSetCookie(cookie=res,nDaysExpires=10)
    }}
  }
  })

# read the cookie and check if everything is ok
observeEvent(input$readCookie,{
  mxDebugMsg("Read cookies in server")

  mxCatch(title="Read cookie",{
  val <- input$readCookie 
  if( isTRUE( noDataCheck(val) || length(val) ==0) ) return()

  nVal = names(val)
  msg =  "Please enter user name and key"
  # NOTE: initialisation s already done before.
  mxReact$userLogged <- FALSE
  mxReact$userRole <- NULL
  mxReact$userName <- NULL
  mxReact$userId <- NULL
  mxReact$userLastLogin <- NULL
  mxReact$userEmail <- NULL
  pwd <- mxData$pwd
  # check if login and key are in given cookie values
  if(isTRUE("l" %in% nVal && "k" %in% nVal)){
    # Check for secret and session token.
    # if the secret does not match : not done after btnLogin pressed.
  

    if(val$s==mxReact$tempSecret){
      # delete the secret
      mxReact$tempSecret <- NULL
      msg <- character(0)
      idUser <- which(pwd$l==val$l)
      idKey <- which(pwd$k==val$k) 
      match <- isTRUE(idUser == idKey)
      if(isTRUE(match)){
      mxDebugToJs(sprintf("user %s will be loged in ",val$l))  
        # retrieve info about the user
        mxReact$userLogged <- TRUE
        mxReact$userRole <- pwd[idKey,'r']
        mxReact$userName <- pwd[idKey,'u']
        mxReact$userId <- pwd[idKey,'id']
        mxReact$userLastLogin <- pwd[idKey,'d']
        mxReact$userEmail <- pwd[idKey,'e']
        msg <- paste("ACCESS GRANTED FOR:",
          mxReact$userName,
          "with email",mxReact$userEmail,
          "logged as", mxReact$userRole,
          "since",val$d
          )
      } else  {
        msg=paste("ACCESS DENIED",msg,collapse="")
      }
    }
  }

  output$loginValidation <- renderText(msg)   
      })
  })





observeEvent(input$btnLogout,{
  mxUpdateValue(id="loginUser",value="")
  mxUpdateValue(id="loginKey",value="")
  mxSetCookie(cookie=list(s="",k="",l=""),deleteAll=TRUE)
})

#
# ALLOW PARTS
#
observe({
  #NOTE: order is important
  mxReact$allowStoryCreator <- mxAllow(
    logged = mxReact$userLogged,
    roleName = mxReact$userRole,
    roleLowerLimit = 1000
    )
  mxReact$allowStoryReader <- mxAllow(
    logged = mxReact$userLogged,
    roleName = mxReact$userRole,
    roleLowerLimit = 100
    )
  mxReact$allowViewsCreator <- mxAllow(
    logged = mxReact$userLogged,
    roleName = mxReact$userRole,
    roleLowerLimit = 1000
    )
  mxReact$allowToolbox <- mxAllow(
    logged = mxReact$userLogged,
    roleName = mxReact$userRole,
    roleLowerLimit = 100
    )
  mxReact$allowMap <- mxAllow(
    logged = mxReact$userLogged,
    roleName = mxReact$userRole,
    roleLowerLimit = 100
    )
  mxReact$allowCountry <- mxAllow(
    logged = mxReact$userLogged,
    roleName = mxReact$userRole,
    roleLowerLimit = 99
    )
  mxReact$allowAdmin <- mxAllow(
    logged = mxReact$userLogged,
    roleName = mxReact$userRole,
    roleLowerLimit = 1000
    )

})

observe({
  enable = FALSE
  if(
    mxReact$allowViewsCreator &&
    isTRUE(mxReact$mapPanelMode == "mapViewsCreator")
    ){
    enable <- TRUE
  }
  mxReact$enableViewsCreator <- enable
})


observe({
  enable = FALSE
  if(
    mxReact$allowViewsCreator &&
    isTRUE(mxReact$mapPanelMode == "mapViewsToolbox")
    ){
    enable <- TRUE
  }
  mxReact$enableToolbox <- enable
})
