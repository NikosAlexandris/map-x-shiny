/*                             
  _ __ ___   __ _ _ __   __  __
 | '_ ` _ \ / _` | '_ \  \ \/ /
 | | | | | | (_| | |_) |  >  < 
 |_| |_| |_|\__,_| .__/  /_/\_\
                 | |           
                 |_|           
 mapx guided tour using bootstrapTour
 http://bootstraptour.com/api/

*/
var txt = {};

/* tour text by language */

/* function to check if elemnt is in view port */
/* http://stackoverflow.com/questions/487073/check-if-element-is-visible-after-scrolling */
function isVisible(e) {
    var el = document.getElementById(e);
    var elemTop = el.getBoundingClientRect().top;
    var elemBottom = el.getBoundingClientRect().bottom;
    var inViewPort = (elemTop >= 0) && (elemBottom <= window.innerHeight) && elemTop != elemBottom;
    return inViewPort;
}

/*  mx tour management  */


function mxStartTour(mxTour,language){

  var steps= [],
  res = {},
  lang ;

  var template = "<div class='popover tour'>"+
    "<div class='arrow'></div>"+
    "<h3 class='popover-title'></h3>"+
    "<hr>"+
    "<div class='popover-content'></div>"+
    "<hr>"+
    "<div class='popover-navigation'>"+
    "<button class='btn btn-md btn-modal' data-role='prev'><i class='fa fa-chevron-left'></i></button>"+
    "<button class='btn btn-md btn-modal' data-role='next'><i class='fa fa-chevron-right'></i></button>"+
    "<button class='btn btn-md btn-modal' data-role='end'><i class='fa fa-stop'></i></button>"+
    "</div>"+
    "</nav>"+
    "</div>";

  if(typeof language == "undefined" ){
    lang = $("#selectLanguage").val();
    if(typeof lang == "undefined" ){
      lang = "eng" ;
    }
  }else{
    lang = language;
  }

  for(var el in mxTour){

    /*   if( el == "btnViewsCreator"){
          debugger;
       }
      */    

    if(isVisible(el)){
      res = { 
        element:"#"+el,
        title:mxTour[el][lang].title,
        content:mxTour[el][lang].content
      };
      for(var o in mxTour[el].opt){
        res[o] = mxTour[el].opt[o];
      }
      steps.push(res);
    }
  }
  /* Tour creation */

  tour =  new Tour({
    template : template,
    backdrop: false,
    steps : steps,
    storage : false,
    autoscroll: false
  });

  tour.init();
  tour.end();
  tour.start(true);

}




