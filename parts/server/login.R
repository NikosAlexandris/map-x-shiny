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
      if(!is.na(val) && !is.null(val)){
        str <- sprintf("document.cookie='%s=%s';",names(val),val)
        cmd <- paste0(cmd,str,collapse="")
      }
    }
  }
  if(length(cmd)>0){
    session$sendCustomMessage(
      type="mxSetCookie",
      list(code=cmd)
      )
  }
}

mxReact <- reactiveValues(
  mxLogged = FALSE,
  mxRole = character(0),
  mxUser = character(0),
  mxSecret = mxCreateSecret() 
  )

# set the first secret


observeEvent(session$onFlushed,{
  cat("Session flushed\n")
  mxSetCookie(cookie=list(s=mxReact$mxSecret))
})



observeEvent(input$btnLogin,{
  if (mxReact$mxLogged == FALSE) {
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
  if(length(val)<1)return()
  if(val$s==mxReact$mxSecret){
    # delete the secret
    mxReact$mxSecret <- NULL
    
    msg = character(0)
    idUser <- which(pwd$l==val$l)
    idKey <- which(pwd$k==val$k) 
    match <- isTRUE(idUser == idKey)
    if(isTRUE(match)){
      # retrieve info about the user
      mxReact$mxLogged <- TRUE
      mxReact$mxRole <- pwd[idKey,'r']
      mxReact$mxUser <- pwd[idKey,'u']
      msg= paste(mxReact$mxUser,"logged as", mxReact$mxRole)
    } else  {
      msg="Authentication  required"
    }

    output$loginValidation <- renderText(msg)   

  }

      })


observe({
print(mxReact$mxLogged)
})

observeEvent(input$btnLogout,{
  cat("log out requested\n")
  mxSetCookie(cookie=res,deleteAll=TRUE)
      })
