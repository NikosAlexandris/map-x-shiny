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


mxTour = {

  "btnNavHome":{
    eng:{
      title:"Home",
      content:"Button leading to the top section"
    },
    fre:{
      title:"Accueil",
      content:"Lien vers la page d'accueil"
    }
  },
  "btnNavMap":{
    eng:{
      title:"Map",
      content:"Button leading to the map section"
    },
    fre:{
      title:"Carte",
      content:"Lien vers la carte interactive"
    }
  },
  "btnLogin":{
    eng:{
      title:"Authentication",
      content:"Button to confirm credential and launch map-x"
    },
    fre:{
      title:"Authentification",
      content:"Bouton pour s'authentifier et accéder à l'application"
    }
  },
  "btnLogout":{
    eng:{
      title:"Sign out",
      content:"Button to sign out"
    },
    fre:{
      title:"Quitter",
      content:"Bouton pour quitter l'application"
    }
  }
};



/* function to check if elemnt is in view port */
/* http://stackoverflow.com/questions/487073/check-if-element-is-visible-after-scrolling */
function isVisible(e) {
    var el = document.getElementById(e);
    var elemTop = el.getBoundingClientRect().top;
    var elemBottom = el.getBoundingClientRect().bottom;
    var inViewPort = (elemTop >= 0) && (elemBottom <= window.innerHeight);
    return inViewPort;
}


/*  Populate steps */



lang = "en";


function mxStartTour(mxTour,language){
  
  var steps= [];
  var res = {};
  var lang ;

  if(typeof language == "undefined" ){
    lang = $("#selectLanguage").val();
    if(typeof lang == "undefined" ){
      lang = "eng" ;
    }
  }else{
    lang = language;
  }

  for(var el in mxTour){
    if(isVisible(el)){
      res = { 
        element:"#"+el,
        title:mxTour[el][lang].title,
        content:mxTour[el][lang].content
      };
      steps.push(res);
    }
  }
  /* Tour creation */

  tour =  new Tour({
    backdrop: false,
    steps : steps,
    storage : false,
    autoscroll: false
  });

  tour.init();
  tour.start(true);

}




