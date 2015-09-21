


observe({
  allowMap <- mxAllow(
    logged = mxReact$mxLogged,
    roleName = mxReact$mxRole,
    roleLowerLimit = 101
    )
  mxUiEnable(id="btnNavMap",enable=allowMap)
  
  allowCountry <- mxAllow(
    logged = mxReact$mxLogged,
    roleName = mxReact$mxRole,
    roleLowerLimit = 99
    )

  mxUiEnable(id="btnNavCountry",enable=allowCountry)


})


