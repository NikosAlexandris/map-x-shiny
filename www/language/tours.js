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

  "btnLogin":{
    eng:{
      title:"Authentication",
      content:"Button to confirm credentials and launch MAP-X"
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
  },
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
      content:"Button leading to the Map section"
    },
    fre:{
      title:"Carte",
      content:"Lien vers la carte interactive"
    }
  },
  "btnNavCountry":{
    eng:{
      title:"Country Profile",
      content:"Link to section with country statistics"
    },
    fre:{
      title:"Profil Pays",
      content:"Lien vers la section des statistiques des pays"
    }
  },
  "btnNavAdmin":{
    eng:{
      title:"Administration Panel",
      content:"Link to the application's administration panel"
    },
    fre:{
      title:"Panneau d'administration",
      content:"Link vers le Panneau d'administration de l'application"
    }
  },
  "btnNavAbout":{
    eng:{
      title:"About",
      content:"Background information about the project"
    },
    fre:{
      title:"À propos",
      content:"Informations générales sur le projet"
    }
  },
  "btnNavContact":{
    eng:{
      title:"Contact",
      content:"Contact the development team"
    },
    fre:{
      title:"Panneau d'administration",
      content:"Contacter l'équipe de développement"
    }
  },
  "btnMapTools":{
    eng:{
      title:"Map Tools",
      content:"Hovering over this icon, reveals a toolbar related to the Map section. Click on it once to activate it."
    },
    fre:{
      title:"Map Tools",
      content:"Hovering over this icon, reveals a toolbar related to the Map section. Click on it once to activate it."
    }
  },
  "btnViewsExplorer":{
    eng:{
      title:"Views Explorer",
      content:"Activate the Views Explorer inside the (left) sidebar"
    },
    fre:{
      title:"Explorateur des Vues",
      content:"Activer l'Explorateur des Vues à l'intérieur du (à gauche) encadré lateral"
    }
  },
  "btnViewsCreator":{
    eng:{
      title:"Views Creator",
      content:"Use this tool to create a custom view of a map layer. +++"
    },
    fre:{
      title:"Créateur des Vues",
      content:"Créer une vue de carte personnalisée."
    }
  },
  "btnStoryReader":{
    eng:{
      title:"Story Reader",
      content:"This opens the Story Reader inside the side panel. "
    },
    fre:{
      title:"Story Reader",
      content:"This opens the Story Reader inside the side panel. "
    }
  },
  "btnViewsConfig":{
    eng:{
      title:"Views Configurator",
      content:"Access the Views Configurator and customise the way map layers appear."
    },
    fre:{
      title:"Views Configurator",
      content:"Access the Views Configurator and customise the way map layers appear."
    }
  },
  "btnViewsToolbox":{
    eng:{
      title:"Views Toolbox",
      content:"+++"
    },
    fre:{
      title:"Views Toolbox",
      content:"+++"
    }
  },
  "btnDraw":{
    eng:{
      title:"Draw",
      content:"+++"
    },
    fre:{
      title:"Draw",
      content:"+++"
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

/*    if( el == "btnMapTools"){
        debugger};
*/

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




