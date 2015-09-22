


observe({
  allowMap <- mxAllow(
    logged = mxReact$userLogged,
    roleName = mxReact$userRole,
    roleLowerLimit = 101
    )
  mxUiEnable(id="btnNavMap",enable=allowMap)
  
  allowCountry <- mxAllow(
    logged = mxReact$userLogged,
    roleName = mxReact$userRole,
    roleLowerLimit = 99
    )

  mxUiEnable(id="btnNavCountry",enable=allowCountry)


})


