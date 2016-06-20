#                             
#  _ __ ___   __ _ _ __   __  __
# | '_ ` _ \ / _` | '_ \  \ \/ /
# | | | | | | (_| | |_) |  >  < 
# |_| |_| |_|\__,_| .__/  /_/\_\
#                 | |           
#                 |_|           
# navigation bar buttons enabler



observe({
  mxUiEnable(id="btnNavMap",enable=reactUser$allowMap)
  mxUiEnable(id="btnNavCountry",enable=reactUser$allowCountry)
  mxUiEnable(id="btnNavSettings",enable=reactUser$allowProfile)
})


