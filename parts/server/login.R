#### Log in module ###


mxCreateSecret =  function(n=20){
  stopifnot(require(digest))
  digest::digest(paste(letters[round(runif(n)*24)],collapse=""))
}


#' Save named list of value into cookie
#' Note : don't use this for storing sensitive data, unless you have a trusted network.
#' @param session Shiny session object. By default: default reactive domain.
#' @param cookie Named list holding paired cookie value. e.g. (list(whoAteTheCat="Alf"))
#' @param nDaysExpires Integer of days for the cookie expiration
#' @return NULL
#' @export
mxSetCookie <- function(session=getDefaultReactiveDomain(),cookie=NULL,nDaysExpires=NULL,deleteAll=FALSE){

  cmd=character(0)
  if(deleteAll){
    cmd = "clearListCookies()"
  }else{
    stopifnot(!is.null(cookie) | is.list(cookie))
    if(is.numeric(nDaysExpires) ){
      exp <- as.numeric(as.POSIXlt(Sys.time()+nDaysExpires*3600*24,tz="gmt"))
      cmd <- sprintf("document.cookie='expires='+(new Date(%s*1000)).toUTCString();",exp)
    }

    for(i in 1:length(cookie)){
      val <- cookie[i]
      if(names(val)=="d")stop('mxSetCookie:d is a reserved name')
      if(!is.na(val) && !is.null(val)){
        str <- sprintf("document.cookie='%s=%s';",names(val),val)
        cmd <- paste0(cmd,str,collapse="")
      }
    }
    }
  if(length(cmd)>0){

    #Add date
    addDate <- ";if(document.cookie.indexOf('d=')==-1){document.cookie='d='+new Date();}"
    cmd <- paste(cmd,addDate)

    session$sendCustomMessage(
      type="mxSetCookie",
      list(code=cmd)
      )
  }
}

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
  mxReact$allowViewsCreator <- mxAllow(
    logged = mxReact$userLogged,
    roleName = mxReact$userRole,
    roleLowerLimit = 1000
    )
})

