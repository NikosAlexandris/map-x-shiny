


var tours = {};
var txt = {};






/* tour text by language */


txt = {
  "#btnLogin":{
    en:{
      title:"Authentication",
      content:"Button to confirm credential and launch map-x"
    },
    fr:{
      title:"Authentification",
      content:"Bouton pour s'authentifier et accéder à l'application"
    }
  },
  "#btnLogout":{
    en:{
      title:"Sign out",
      content:"Button to sign out"
    },
    fr:{
      title:"Quitter",
      content:"Bouton pour quitter l'application"
    }
  }
};



/* steps */


stepsIntro = [];
res = {};
lang = "en";
for(var el in txt){
 res = { 
   element:el,
   title:txt[el][lang].title,
   content:txt[el][lang].content
 };
 stepsIntro.push(res);
}

tours.intro =  new Tour({
  steps : stepsIntro
});


tours.intro.init();


