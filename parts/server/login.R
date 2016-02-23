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
#observeEvent(input$documentIsReady,{
  
  tempSecret <-  mxCreateSecret()
  
  mxSetCookie(
    cookie=list(t=session$token,s=tempSecret),
    read=T
    )
  
  mxReact$tempSecret <- tempSecret
  mxReact$userLogged <- FALSE
  mxReact$userRole <- character(0)
  mxReact$userName <- character(0)
  mxReact$userId <- integer(0)
  mxReact$sessionToken <- session$token
#})



# Language selection
observeEvent(input$selectLanguage,{
  selLanguage = input$selectLanguage
  if(!noDataCheck(selLanguage)){
    mxReact$selectLanguage = selLanguage
    mxSetCookie(
      cookie=list("lang"=selLanguage),
      read=FALSE
      ) 
  } 
})




# if the user press the login button and is not yet logged, write a cookie
# the cookie will be read again server side.
observeEvent(input$btnLogin,{
  if ( mxReact$userLogged == FALSE ) {
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
        mxSetCookie(
          cookie=res,
          nDaysExpires=10,
          read=TRUE
          )
    }}
  }
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
  mxReact$userLogged <- FALSE
  mxReact$userRole <- character(0)
  mxReact$userName <- character(0)
  mxReact$userId <- integer(0)
  mxUpdateValue(id="loginUser",value="")
  mxUpdateValue(id="loginKey",value="")
  mxReact$tempSecret <- mxCreateSecret()
  mxSetCookie(
    cookie=list(s="",k="",l="",d="",t=""),
    deleteAll=TRUE,
    read=FALSE
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
