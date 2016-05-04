
#
# story map functions
#




#' Parse vimeo string 
#' @param text Story map text with @vimeo( id ; desc ) tag
#' @return html enabled version
#' @export
mxParseVimeo <- function(text){

  # remplacement string
  html <- tags$div(
  tags$iframe(
    src=sprintf("https://player.vimeo.com/video/%1$s?autoplay=0&color=ff0179",'\\1'),
    width="300",
    frameborder="0",
    webkitallowfullscreen="",
    mozallowfullscreen="",
    allowfullscreen=""
    ),
  span(style="font-size=10px",'\\2')
  )

  # regular expression
  expr <- "@vimeo\\(\\s*([ 0-9]+?)\\s+[;]+\\s*([ a-zA-Z0-9,._-]*?)\\s*\\)"

  # substitute
  gsub(
    expr,
    html,
    text
    )

}


#' Parse view string
#' @param test Story map text with @view_start( name ; id ; extent ) ... @view_end tags
#' @return parsed html 
#' @export
mxParseView <- function(text){

  html <- tags$div(
    class="mx-story-section mx-story-dimmed",
    `mx-map-title`="\\1",
    `mx-map-id`="\\2",
    `mx-map-extent`="[\\3]",
    "\\4"
    )


 # regular expression
#  expr <- "@view_start\\(\\s*(.*?)\\s*[;]\\s*(.*?)\\s*[;]\\s*([0-9\\.,-]*?)\\s*\\)(.*?)@view_end"
  expr <- "@view_start\\(\\s*([ a-zA-Z0-9,._-]*?)\\s*;+\\s*([ a-zA-Z]*?)\\s*[;]+\\s*([ 0-9,\\.\\-]+?)\\s*\\)(.*?)@view_end"
  # substitute
  gsub(
    "(lng):|(lat):|(zoom):",
    "",
    text
    ) %>%
  gsub(
    expr,
    html,
    .
    )
 
}

#' Parse story map : markdown, R, view and video
#' @param test Story map text
#' @return parsed html 
#' @export
mxParseStory <- function(txtorig,knit=T,toc=F){

  # Parse knitr with options from markdownHTMLoptions()
  txt <- knitr::knit2html(text=txtorig,quiet = TRUE, 
    options=c(ifelse(toc,"toc",""),"base64_images","highlight_code","fragment_only")
    ) %>%
    mxParseView() %>%
    mxParseVimeo() 

    return(txt)
    
}


#' Get story map text
#' @param dbInfo Named list containing information for db connection : host, password, etc.
#' @param id Id of the story map to get
#' @param textColumn Column name containting the story map unparsed text
#' @return Story map unparsed text
#' @export
mxGetStoryMapText <- function(dbInfo,id,textColumn="content_b64"){
  tblName <- mxConfig$storyMapsTableName
  res <- data.frame()
  if(mxDbExistsTable(dbInfo,tblName)){
    q <- sprintf("SELECT %1$s FROM %2$s WHERE \"id\"='%3$s' and \"archived\"='f'",
      textColumn,
      tblName,
      id
      )
    res <- mxDbGetQuery(q) 
  }
  if(textColumn %in% names(res)){
  res <- mxDecode(res$content_b64)
  }
  return(res)
}
#' @export
mxGetStoryMapName <- function(dbInfo){
  tblName <- mxConfig$storyMapsTableName
  if(!mxDbExistsTable(dbInfo,tblName)) return(data.frame())
  q <- sprintf("SELECT name FROM %1$s WHERE \"archived\"='f'",tblName)
  res <- mxDbGetQuery(q) 
  return(res)
}

