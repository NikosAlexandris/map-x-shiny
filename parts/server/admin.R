#
# ADMIN SECTION RESTRICTED AREA
#

observe({
  #mxDebugMsg(paste("ALLOW ADMIN TEST=",mxReact$allowAdmin))
  mxUiEnable(id="sectionAdmin",enable=mxReact$allowAdmin) 
})

observe({
  if(mxReact$allowAdmin){

    mxReact$pwd <- pwd


    observe({
      mxCatch(title='Populate admin tables',{
        pwdIn <- mxReact$pwd
        output$userTable <- renderHotable({
          nPwd <- names(pwdIn) 
          newId <- max(as.numeric(pwdIn$id))+1
          newEntry <- rep(NA,8)
          pwdOut <- rbind(pwdIn,newEntry)
          pwdOut$select <- FALSE
          pwdOut <- pwdOut[,c('select',nPwd)]
          pwdOut[nrow(pwdOut),'id'] <- newId
          pwdOut
        },stretch='last',readOnly=c(2))
})
    })


    observeEvent(input$btnAdmRmUser,{
      tbl <- na.omit(hot.to.df(input$userTable))
      mxReact$pwd <- tbl[!tbl$select,names(tbl)[!names(tbl) %in% "select"]]
    })
  }

})
