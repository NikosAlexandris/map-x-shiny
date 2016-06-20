#                             
#  _ __ ___   __ _ _ __   __  __
# | '_ ` _ \ / _` | '_ \  \ \/ /
# | | | | | | (_| | |_) |  >  < 
# |_| |_| |_|\__,_| .__/  /_/\_\
#                 | |           
#                 |_|           
# Admin / configuration section

tags$section(id="sectionAdmin",class="mx-section-container container-fluid mx-hide",
  tagList(
    div(class="row",
      div(class="col-lg-10 col-lg-offset-1",
        h2("Settings"),
        tabsetPanel(
          tabPanel("PROFIL",
            tags$div(class="col-xs-12 col-md-6",
              jedOutput("uiUserProfil")
              ),
            tags$div(
              class="col-xs-12 col-md-6 mx-allow-admin-role",
              selectInput(
                inputId="selectUserForRole",
                label="Select user",
                choices=""
                ),
              jedOutput("uiUserAdmin")
              )
            ),
          tabPanel("VIEWS",
            uiOutput("uiSettingViews")
            ),
          tabPanel("LAYERS",
            uiOutput("uiSettingLayers")
            ),
          tabPanel("STORY MAPS",uiOutput("uiSettingStoryMaps")
            )
          )
        )
      )
    )
  )

