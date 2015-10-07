#### Log in module ###




mxReact <- reactiveValues(
  userLogged = FALSE,
  userRole = character(0),
  userName = character(0),
  mxSecret = mxCreateSecret() 
  )

# set the first secret


observeEvent(session$onFlushed,{
  cat("Session flushed\n")
  mxSetCookie(cookie=list(s=mxReact$mxSecret))
})



observeEvent(input$btnLogin,{
  if (mxReact$userLogged == FALSE) {
    if (!is.null(input$loginUser)) {
      if (input$btnLogin > 0) {
        lUser <- input$loginUser
        lKey <- input$loginKey
        lSec <- mxCreateSecret()
        res <- list(
          l = input$loginUser,
          k = input$loginKey,
          s = lSec
          )
        mxReact$mxSecret <- lSec
        mxSetCookie(cookie=res,nDaysExpires=10)
    }}
  }
      })


observeEvent(input$readCookie,{
  cat("Read cookies done.\n")
  val = input$readCookie 
  nVal = names(val)
  msg =  "Plase enter user name and key"
  mxReact$userLogged <- FALSE
  mxReact$userRole <- NULL
  mxReact$userName <- NULL
  mxReact$userLastLogin <- NULL
  mxReact$userEmail <- NULL

  if(isTRUE("l" %in% nVal && "k" %in% nVal)){
    if(val$s==mxReact$mxSecret){
      # delete the secret
      mxReact$mxSecret <- NULL
      msg = character(0)
      idUser <- which(pwd$l==val$l)
      idKey <- which(pwd$k==val$k) 
      match <- isTRUE(idUser == idKey)
      if(isTRUE(match)){
        # retrieve info about the user
        mxReact$userLogged <- TRUE
        mxReact$userRole <- pwd[idKey,'r']
        mxReact$userName <- pwd[idKey,'u']
        mxReact$userLastLogin <- pwd[idKey,'d']
        mxReact$userEmail <- pwd[idKey,'e']
        msg= paste("ACCESS GRANTED FOR:",
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


observe({
print(mxReact$userLogged)
})

observeEvent(input$btnLogout,{
  mxSetCookie(cookie=res,deleteAll=TRUE)
      })

#
# ALLOW PARTS
#
observe({
  #NOTE: order is important
  mxReact$allowViewsCreator <- mxAllow(
    logged = mxReact$userLogged,
    roleName = mxReact$userRole,
    roleLowerLimit = 1000
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

