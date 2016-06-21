#                             
#  _ __ ___   __ _ _ __   __  __
# | '_ ` _ \ / _` | '_ \  \ \/ /
# | | | | | | (_| | |_) |  >  < 
# |_| |_| |_|\__,_| .__/  /_/\_\
#                 | |           
#                 |_|           
# administrative panel management

# ui enable
observe({
  mxUiEnable(id="sectionAdmin",enable=reactUser$allowProfile) 
})



#
# Set admin  / settings schema
#

observe({
  
  lang <- reactUser$language 

  reactSchema$preferences = list(
    title=ifelse(lang=="eng","Preferences","Préférences"),
    type="object",
    properties=list(
      language=list(
        type="string",
        title=ifelse(lang=="eng","Language","Langue"),
        enum=c("eng","fre"),
        minLength=1,
        required=TRUE,
        options=list(
          enum_titles=c("English","Français (partiel)")
          )
        ),
      about=list(
        type="string",
        format="textarea",
        default=" ",
        title=ifelse(lang=="eng","About","À propos"),
        required=TRUE
        )
      )
    )


  if(isTRUE(reactUser$data$role$level == 0)){
    # superuser 
    cntryList = c("world",unlist(mxConfig$countryListChoices,use.names=F))
  }else{
    cntryList = c("world",reactProject$name,"")
  }


  rolesList <- mxGetListValue(reactUser$data,c("role","desc","profile"))

  reactSchema$role = list(
    title=ifelse(lang=="eng","Selected user roles","Roles de l'utilisateur selectionné"),
    type="object",
    properties=list(
      roles=list(
        title=ifelse(lang=="eng","Role","Role"),
        type="array",
        format="table",
        uniqueItems=TRUE,
        items = list(
          type = "object",
          title = ifelse(lang=="eng","Role","Role"),
          properties = list(
            project = list(
              title = ifelse(lang=="eng","Location","Lieu"),
              type = "string",
              enum = cntryList,
              required =TRUE
              ),
            role =list(
              title = ifelse(lang=="eng","Role","Role"),
              type = "string",
              enum =  rolesList,
              required =TRUE
              )
            )
          )
        )
      )
    )

})


#
# populate user list
#

observe({
  userList <- list()
  allowAdmin <- reactUser$allowAdmin 
  #
  # Toggle ui
  #
  mxUiEnable(class="mx-allow-admin-role",enable=allowAdmin)
  #
  # Get user list
  #
  if(allowAdmin){
    canEdit <-  mxGetListValue(reactUser$data,c("role","desc","profile"))

    selfId <- reactUser$data$id
    currProject <- reactProject$name 

    #users = mxDbGetUserInfoByRole(
    users <- mxDbGetUserByRoles(roles=canEdit)

    userList <- unique(users$id)
    names(userList) <- unique(users$email)
  }
  #
  # Update user list
  #
  updateSelectInput(session,
    inputId="selectUserForRole",
    choices=userList
    )
})

#
# Set up default schema
#

output$uiUserAdmin <- jedRender({
  mxDebugMsg("Set schema user admin")
  jedSchema(
    list(
      schema = reactSchema$role
      )
    )
})






observe({

  allowed <- isTRUE(reactUser$allowAdmin)
  usrId <- input$selectUserForRole
  hasId <- !noDataCheck(usrId)

  if(!allowed || !hasId ) return()

  #
  # Get selected user data info
  #
  usrDat <- mxDbGetUserInfoList(id=usrId)
  #
  # Get roles for selected user
  #
  dat <- mxGetListValue(usrDat,c("data","admin","roles"))
  #
  # Update jed
  #
  mxDebugMsg("update jedUpdate")
  jedUpdate(
    editorId = "uiUserAdmin",
    values = list(roles=dat)
    )

})


observeEvent(input$uiUserAdmin_values,{
  val <- input$uiUserAdmin_values$roles
  if(isTRUE(length(val)>0)){

    mxDbUpdate(
      table = mxConfig$userTableName,
      idCol = 'id',
      id = input$selectUserForRole,
      column = 'data',
      value = val,
      jsonPath = c("admin","roles")
      )

  }
})



observe({
if(reactUser$allowProfile){
usr <- reactUser$data
mxDebugMsg("Set user default preference in jed")
 output$uiUserProfil <- jedRender({
   # get preferences
   dat <- mxGetListValue(reactUser$data,c("data","user","preferences"))
   # clean NOTE:old preference item to be removed.
   dat <- dat[!names(dat) %in% c("last_story","last_project")]
   # default 
   if(is.null(dat$about)) dat$about = ""
   if(is.null(dat$language)) dat$language = "eng"

    jedSchema(
      list(
        schema = reactSchema$preferences,
        startval = dat
        )
      )
 })
}
})

observeEvent(input$uiUserProfil_values,{

mxDebugMsg("User profile received, test for change and update db / react")
    # update reactive value and db if needed
    mxDbUpdateUserData(reactUser,
      path=c("data","user","preferences"),
      value=input$uiUserProfil_values
      )
})



