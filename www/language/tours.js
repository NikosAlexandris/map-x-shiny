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
      content:"Click here to confirm user credentials and launch the application"
    },
    fre:{
      title:"Authentification",
      content:"Bouton pour s'authentifier et accéder à l'application"
    }
  },
  "btnLogout":{
    eng:{
      title:"Sign out",
      content:"Click here to sign out"
    },
    fre:{
      title:"Quitter",
      content:"Bouton pour quitter l'application"
    }
  },
  "btnNavHome":{
    eng:{
      title:"Home",
      content:"This button will be always visible and lead to the top section/frontpage"
    },
    fre:{
      title:"Accueil",
      content:"Lien vers la page d'accueil"
    }
  },
  "btnNavMap":{
    eng:{
      title:"Map",
      content:"Follow this link to access the Map section"
    },
    fre:{
      title:"Carte",
      content:"Lien vers la carte interactive"
    }
  },
  "btnNavCountry":{
    eng:{
      title:"Country Profile",
      content:"This button links to a section with information and statistics about the selected country"
    },
    fre:{
      title:"Profil Pays",
      content:"Lien vers la section des statistiques des pays"
    }
  },
  "btnNavAdmin":{
    eng:{
      title:"Administration Panel",
      content:"From here, you can access the application's administration panel"
    },
    fre:{
      title:"Panneau d'administration",
      content:"Link vers le Panneau d'administration de l'application"
    }
  },
  "btnNavAbout":{
    eng:{
      title:"About",
      content:"Read background information about the project"
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
      content:"Hover over this icon to reveal a toolbar related to the Map section. Click on it once to activate it."
    },
    fre:{
      title:"Map Tools",
      content:"Hovering over this icon, reveals a toolbar related to the Map section. Click on it once to activate it."
    }
  },
  "btnViewsExplorer":{
    eng:{
      title:"Views Explorer",
      content:"Open the Views Explorer inside the (left) sidebar"
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
      content:"Activate a toolbox to perform spatial analysis for the map layers of interest"
    },
    fre:{
      title:"Views Toolbox",
      content:"+++"
    }
  },
  "btnDraw":{
    eng:{
      title:"Spatial Toolbox",
      content:"Activate a spatial toolbox to draw points, lines or polygons of interest. Optionally, notifications regarding changes that occur inside the spatial entity of interest "
    },
    fre:{
      title:"Draw",
      content:"+++"
    }
  },
  "btnMapCreatorSave":{
    eng:{
      title:"Save Map ...",
      content:"+++"
    },
    fre:{
      title:"Save Map ...",
      content:"+++"
    }
  },
  "btnZoomToLayer":{
    eng:{
      title:"Zoom to Layer",
      content:"Zoom in to the active layer's entire extent"
    },
    fre:{
      title:"Zoom to Layer",
      content:"Zoom in to the active layer's entire extent"
    }
  },
  "btnViewsRefresh":{
    eng:{
      title:"Refresh View",
      content:"+++"
    },
    fre:{
      title:"Refresh View",
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




