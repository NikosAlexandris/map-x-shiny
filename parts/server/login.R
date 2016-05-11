#                             
#  _ __ ___   __ _ _ __   __  __
# | '_ ` _ \ / _` | '_ \  \ \/ /
# | | | | | | (_| | |_) |  >  < 
# |_| |_| |_|\__,_| .__/  /_/\_\
#                 | |           
#                 |_|           
# login and restriction  management

  
  mxReact$userData <- list()

# Language selection
observeEvent(input$selectLanguage,{
  selLanguage = input$selectLanguage
  if(!noDataCheck(selLanguage)){
    mxReact$selectLanguage = selLanguage
    mxSetCookie(
      cookie=list("mx_language"=selLanguage),
      ) 
  } 
})




mxAutoLogUser <- function(email=NULL,session=shiny::getDefaultReactiveDomain()){
  res = FALSE
  if(!noDataCheck(email)){
    ck <- session$input$cookies
    if(!is.null(ck)){
      dat <- session$input$cookies$mx_data
      if(length(dat)>0 && 'auto_log' %in%  names(dat)){
      }
    }

  }



}


mxCreateUser <-function(email){


}




# email validation 

observe({
  email <- input$loginUserEmail
  val <- mxEmailIsValid(email)
  msg <- ""
  allowLogin <- FALSE
  if(!val){
    msg <- "Please enter a valid email to register or to log in"
  }else{
    known <- mxEmailIsKnown(email) 
    if(known){ 
      msg <- "This email is valid and registered. Click on the login button to get a secret key"
    }else{
      msg <- "This email is valid and not yet registered. Click on login button to register."
    }
    allowLogin <- TRUE
  }
  mxActionButtonState("btnLogin",disable=!allowLogin)

  mxUpdateText("loginValidation",msg)
})




observe({
  dat <- mxDbDecrypt(input$cookies$mx_data)
  if(isTRUE(dat$auto_log))
    mxDebugMsg(sprintf("user %s will be logged in",dat$user))
})


# if the user press the login button and is not yet logged, write a cookie
# the cookie will be read again server side.
observeEvent(input$btnLogin,{


  email <- input$loginUserEmail
  userdata <- mxReact$userData
  cookiedata <- mxDbDecrypt(input$cookies$mx_data) 

  if(!mxEmailIsValid(input$loginUserEmail)) return()
  if(length(mxReact$userData)>0) return()

  if(isTRUE(cookiedata$auto_log)){
    mxDebugMsg("btn login pressed, but user already logged")
    return()
  }else{
    if(!mxEmailIsValid(email)){
      mxDebugMsg(sprintf("email %s is not valid !",email))
    }else{
      if(mxEmailIsKnown(email)){ 
        mxDebugMsg(sprintf("email %s is known",email))
      }else{ 
        mxDebugMsg(sprintf("email %s is already registered",email))
      }
    }
  }


  browser()
  return()

})

# If a read option was set during a mxSetCookie, this will be reevaluate.

observeEvent(input$readCookie,
  {
    mxCatch(title="Read cookie",
      {
        msg <-"Please enter user name and key"
        val <- input$readCookie 
        if( 
          isTRUE( noDataCheck(val) ) ||
          isTRUE( length(val) == 0 ) 
          )  return()

 
        nVal <- names(val)
        pwd <- mxData$pwd
        # check if login and key are in given cookie values
        if(
          isTRUE( mxReact$tempSecret == val$s )
          ){
            if(
              isTRUE( "l" %in% nVal ) && 
              isTRUE( "k" %in% nVal )
              ){
              # change the secret
              mxReact$tempSecret <- mxCreateSecret()
              # get row id for login and key
              idUser <- which(pwd$l==val$l)
              idKey <- which(pwd$k==val$k) 
              # check for match
              if( isTRUE( idUser == idKey ) ){
                # retrieve info about the user
                mxReact$userLogged <- TRUE
                mxReact$userRole <- pwd[idKey,'r']
                mxReact$userName <- pwd[idKey,'u']
                mxReact$userId <- pwd[idKey,'id']
                mxReact$userEmail <- pwd[idKey,'e']
                # set info message
                msg <- sprintf(
                  "Access granted for %1$s. \n Email : %2$s  \n Role : %3$s \n Since : %4$s",
                  mxReact$userName,
                  mxReact$userEmail,
                  mxReact$userRole,
                  date() # THIS WILL BE STORED IN DB
                  )

   
              } else  {

                notUser <- ifelse(
                  length( idUser ) < 1,
                  "Wrong username. ",
                  ""
                  )
                notKey <- ifelse(
                  length( idKey ) < 1,
                  "Wrong key. ",
                  ""
                  )
                # Warning : wrong pass
                msg=paste("Access denied. ",notUser,notKey,sep="",collapse="")
              }
            }
          }

          mxUpdateText("loginValidation",msg)
      })

 

  })





observeEvent(input$btnLogout,{
  mxReact$userData <- NULL
  mxUpdateValue(id="loginUserEmail",value="")
  mxSetCookie(
    deleteAll=TRUE,
    reloadPage=TRUE
    )
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
    roleLowerLimit = 10000
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
