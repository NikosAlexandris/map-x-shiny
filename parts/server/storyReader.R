#                             
#  _ __ ___   __ _ _ __   __  __
# | '_ ` _ \ / _` | '_ \  \ \/ /
# | | | | | | (_| | |_) |  >  < 
# |_| |_| |_|\__,_| .__/  /_/\_\
#                 | |           
#                 |_|           
# story map reader : create list, select and display story map



# Allow story map creator
observe({
  if(mxReact$allowStoryCreator){
    source("parts/server/storyCreator.R",local=TRUE)
  }
})

# available story
mxData$storyMaps <- reactive({
  if(mxReact$mapPanelMode != "mapStoryReader") return()

  newStory <- mxReact$newStoryId

  db <- NULL
  usr <- mxReact$userId
  cnt <- mxReact$selectCountry
  tblName <- mxConfig$storyMapsTableName
 
  # validation
  if(
    isTRUE(!noDataCheck(usr)) && 
    isTRUE(!noDataCheck(cnt)) && 
    isTRUE(mxReact$mapPanelMode == "mapStoryReader") &&
    isTRUE(tblName %in% mxDbListTable(dbInfo))
    ){

      # db : id,user,country,name,desc,content_b64,content_ascii
      q <- sprintf("SELECT * FROM %1$s WHERE country='%2$s'",tblName,cnt)
      db <- mxDbGetQuery(dbInfo,q) 
    
    }else{
      # empty
      db <- data.frame(
        id=NA,
        user=usr,
        country=cnt,
        name=NA,
        desc=NA,

        content_b64=NA,
        content_ascii=NA
        )
    }

  if(!noDataCheck(newStory)){
  db <- rbind(
      db[db$id==newStory,],
      db[db$id!=newStory,]
    )
  }


    mxDebugMsg("Update of storymaps reactive function")
   return(db)
})


observe({
mxCatch(title="Update story selector",{

  if(mxReact$mapPanelMode != "mapStoryReader") return()
  mxDebugMsg("Update story selectize input")
  #
  # Update story map selector 
  #
  db <- mxData$storyMaps() 
  listStory <- db$id
  names(listStory) <-db$name
  updateSelectizeInput(session,"selectStoryId",choices=listStory,server=TRUE,selected=listStory[1])
    })
})


observeEvent(input$selectStoryId,{
  mxCatch(title="Select story id",{
    #
    # Decode selected story
    #
    storyId <- input$selectStoryId
    storyMap <- "Write a story.."
    if(!noDataCheck(storyId,noDataVal="NA")){
      storyMap <- mxData$storyMaps() 
      storyMap <- storyMap[storyMap$id==storyId,"content_b64"]
      if(is.na(storyMap)){
        storyMap <- "Write a story.."
      }else{
        storyMap <- mxDecode(storyMap)
      }
    }else{
      storyMap = " No story map yet :( "
    }
    mxReact$storyMap <- storyMap

    })
})


observeEvent(mxReact$storyMap,{
  storyMap <- mxReact$storyMap
  if(!noDataCheck( storyMap )){
    #
    # Update editor
    #
    mxUpdateText(id="txtStoryMap",text=storyMap)
    mxDebugToJs(list(textStory=storyMap))
    #
    # Parse story map
    #
    txt <- mxParseStory( storyMap )
    # add some blank space
    r <- paste(rep(" ",1000),collapse="")
    txt <- paste(txt,r,sep="")
    # 
    # Send the story to ui
    #
    mxUpdateText(id="mxStoryText",text=txt,addId=T)
  }
})


