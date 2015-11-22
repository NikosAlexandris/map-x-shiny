#                             
#  _ __ ___   __ _ _ __   __  __
# | '_ ` _ \ / _` | '_ \  \ \/ /
# | | | | | | (_| | |_) |  >  < 
# |_| |_| |_|\__,_| .__/  /_/\_\
#                 | |           
#                 |_|           
# navigation bar buttons enabler



observe({
  mxUiEnable(id="btnNavMap",enable=mxReact$allowMap)
  mxUiEnable(id="btnNavCountry",enable=mxReact$allowCountry)
  mxUiEnable(id="btnNavAdmin",enable=mxReact$allowAdmin)
})


