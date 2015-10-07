//
// Get the value of loc object and update text
//

function updateTitlesLang(){
  var lang = $("#selectLanguage").val();
  $("[mx_set_lang]").each(
      function(){
        var a = $(this).attr("mx_set_lang").split(".");
        var attribute = a[0];
        var group = a[1];
        var key = a[2]; 
        var text = loc[a[1]][a[2]][lang];
        if(typeof text == "undefined")text= "NO TRANSLATION";
        if(a[0]=="html"){
          $(this).html(text);
        }else{
          $(this).attr(attribute, text);
        }
      }
      );
}






loc = {
  "navBar":{
    "home": {
      "eng": "Home screen",
      "fre": "Écran de départ"
    },
    "profil": {
      "eng": "Authentication and profil",
      "fre": "Authentification et profil "
    },
    "country": {
      "eng": "Country selection and statistics",
      "fre": "Sélection du pays et statistiques"
    },
    "map": {
      "eng": "Spatial analysis and web mapping",
      "fre": "Analyse spatiale et cartographie interactive"
    },
    "about": {
      "eng": "About",
      "fre": "À propos"
    },
    "admin": {
      "eng": "Admin panel",
      "fre": "Panneau d'administration"
    },
    "contact": {
      "eng": "Contact map-x team",
      "fre": "Contacter l'équipe map-x"
    }
  },
  "mapLeft": {
    "lock":{
      "eng": "Avoid scroll on left panel",
      "fre": "Eviter le scroll sur le paneau de gauche"
    },
    "hide": {
      "eng": "Hide pannel",
      "fre": "Masquer le paneau"
    },
    "explorer": {
      "eng": "Display the map views explorer",
      "fre": "Afficher l'explorateur de vues"
    },
    "add": {
      "eng": "Add data and configure views",
      "fre": "Ajouter des données et configurer les vues"
    },
    "info": {
      "eng": "Display info panel",
      "fre": "Afficher le panneau d'information"
    },
    "config": {
      "eng": "Display general configuration panel",
      "fre": "Afficher le panneau de configuration général "
    },
    "toolbox": {
      "eng": "Display spatial toolbox panel",
      "fre": "Afficher la boîte à outils spatiale"
    }
  },
  "login":{
    "title":{
      "eng":"User authentication",
      "fre":"Authentification de l'utilisateur"
    }
  }
};
