#
# ADMIN SECTION RESTRICTED AREA
#

observe({
  #mxDebugMsg(paste("ALLOW ADMIN TEST=",mxReact$allowAdmin))
  mxUiEnable(id="sectionAdmin",enable=mxReact$allowAdmin) 
})

observe({
  if(mxReact$allowAdmin){
    #mxReact$pwd <- mxData$pwd
    #
    # USERS
    # 
    mxCatch(title='Populate admin tables',{
      # send data to table
      output$tableUsers <- renderHotable({
        #pwdIn <- mxReact$pwd
        pwdIn <- mxData$pwd
        nPwd <- names(pwdIn) 
        newId <- max(as.numeric(pwdIn$id))+1
        newEntry <- rep(NA,8)
        pwdOut <- rbind(pwdIn,newEntry)
        pwdOut$select <- FALSE
        pwdOut <- pwdOut[,nPwd]
        pwdOut[nrow(pwdOut),'id'] <- newId
        pwdOut
      },stretch='last')
      # handle btn
      observeEvent(input$btnAdmRmUser,{
        tbl <- na.omit(hot.to.df(input$userTable))
        #mxReact$pwd <- tbl[!tbl$select,names(pwd)]
        mxData$pwd <- tbl[!tbl$select,names(pwd)]
      })
})




    #
    # VIEWS
    #

    mxCatch(title="Admin views list ",{
      # send data to table
      output$tableViews <- renderHotable({
        vList <- mxReact$views
        tbl = data.frame(
          id="-",
          country="-",
          title="-",
          editor="-",
          validated="-",
          layer="-",
          dateCreated="-",
          stringsAsFactors=FALSE
          )
        if(!noDataCheck(vList)){
          vName = names(vList)
          for(i in 1:length(vName)){
            v = vName[i]
            vDat <- vList[[v]][names(tbl)]
            vDat <- as.data.frame(vDat[names(tbl)],stringsAsFactors=FALSE)
            vDat[is.na(vDat)]<-""
            if(i>1){
              tbl <- rbind(tbl,vDat)
            }else{
              tbl <- vDat
            }
          }
          tbl$select=FALSE
          tbl<- tbl[,unique(c("select",names(tbl)))]
        }

        return(tbl)
      })
      #  handle remove button

      observeEvent(input$btnAdmRmViews,{
        tbl<-hot.to.df(input$tableViews)
        viewsToRemove<-tbl[tbl$select,"id"]
        if(length(viewsToRemove)>0){ 
          mxReact$viewsToRemove <- viewsToRemove
          outConfirm <- tagList(
            p("Are you sure to remove those views:",paste(viewsToRemove,sep=", ")),
            actionButton("btnConfirmRmViews","yes"),
            actionButton("btnCancenRmViews","cancel")
            )
        }else{
          outConfirm <- tagList()  
        }
        output$confirmRmViews<-renderUI(outConfirm)

      })

      observeEvent(input$btnConfirmRmViews,{
        viewsToRemove <- mxReact$viewsToRemove
        tryCatch({
          d <- dbInfo
          drv <- dbDriver("PostgreSQL")
          con <- dbConnect(drv, dbname=d$dbname, host=d$host, port=d$port,user=d$user, password=d$password)
          t <- mxConfig$viewsListTableName
          for(i in viewsToRemove){
            q <- sprintf("DELETE FROM %s WHERE id='%s';",t,i)
            dbGetQuery(con,q)
          }
        },finally=if(exists('con')){dbDisconnect(con)}
          )
        mxReact$viewsListUpdate<-runif(1)
        output$confirmRmViews<-renderUI(tagList())
      })

      observeEvent(input$btnCancenRmViews,{ 
        output$confirmRmViews<-renderUI(tagList())
      })





})


  }

})
