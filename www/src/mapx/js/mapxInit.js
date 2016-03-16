

/* collapse top nav if href is not section top */
$(function() {
  $('a.page-scroll').bind('click', function(event) {
    if (  $(this).attr('href') != "#sectionTop" ) {
      $(".navbar-fixed-top").addClass("top-nav-collapse");
    } else {
      $(".navbar-fixed-top").removeClass("top-nav-collapse");
    }
  });
});

// Closes the Responsive Menu on Menu Item Click
$('.navbar-collapse ul li a').click(function() {
  $('.navbar-toggle:visible').click();
});






// background selector

bgClasses = ["mx-top-bg-1","mx-top-bg-2","mx-top-bg-3"];

function changeBg(){
var bgClass = bgClasses[Math.floor(Math.random()*bgClasses.length)];
$("#sectionTop").addClass(bgClass);
}



// request meta for a layer
function  mxRequestMeta(viewId){
  var trigger = new Date();
  Shiny.onInputChange("mxRequestMeta", { 
    id:viewId, 
    time:trigger
  }
  );
}


// When document is ready
$( document ).ready(function() {
// change top section background
  changeBg();
// remove loading screen
$("#sectionLoading").css({display:'none'});

$('#storyMapModal').draggable({ 
  handle:'#storyMapModalHandle',
  containment: '#sectionMap'
});
$('#btnStoryCreator').click(
  function(){
    $id = $('#storyMapModal');
    $id.toggleClass('mx-hide');
  }
);


// update map panel element
  updateMapElement();
// update documentIsReady input
Shiny.onInputChange("documentIsReady",new Date());

// set language
Shiny.onInputChange("cookiesLanguage",Cookies.get("lang"));
// set country
Shiny.onInputChange("cookiesCountry",Cookies.get("country"));
// shiny binding to set cookie. After cookie set, read it again.
Shiny.addCustomMessageHandler("mxSetCookie",
    function(e) {

      if( e.expiresInSec.length === 0 ){
        exp = undefined ;
      }else{
        exp = e.expiresInSec;
      }


      if(e.deleteAll){
        exp = '01/01/2012';
      }

      for( var c  in e.cookie){
        Cookies.set(c,e.cookie[c],{
          'path':e.path,
          'domain':e.domain,
          'expires':exp}
          );
      }

      if(e.read){
        readCookie(); 
      }

      if(e.deleteAll){
        location.reload();
      }

    }
);



Shiny.addCustomMessageHandler("jsonToObj",
    function(jsonRaw) {
      window[jsonRaw.name] = JSON.parse(jsonRaw.json);
    }
    );


Shiny.addCustomMessageHandler("jsCode",
    function(message) {
      eval(message.code);
    }
    );

Shiny.addCustomMessageHandler("jsDebugMsg",
    function(m) {
      console.log(m.msg);
    }
);

Shiny.addCustomMessageHandler("mxSetButonState",
    function(r) {

      if(r.disable === true){
        $("#"+r.id)
          .addClass("btn-danger")
          .removeClass("btn-default")
          .removeClass("btn-warning")
          .attr("disabled",true); 
      }else if(r.warming === true){ 
        $("#"+r.id)
          .addClass("btn-warning")
          .removeClass("btn-default")
          .removeClass("btn-danger")
          .attr("disabled",false); 
      }else{
        $("#"+r.id)
          .addClass("btn-default")
          .removeClass("btn-danger")
          .removeClass("btn-warning")
          .attr("disabled",false); 
      }
    }
    );

Shiny.addCustomMessageHandler("mxUiEnable",
    function(r) {
      if(r.enable === true){
        $(r.element).removeClass(r.classToRemove);
      }else{ 
        $(r.element).addClass(r.classToRemove);
      }
    }
    );


Shiny.addCustomMessageHandler("mxRemoveEl",
    function(e) {
    $(e.element).remove();
    }
);

Shiny.addCustomMessageHandler("mxUpdateValue",
    function(e) {
      el = document.getElementById( e.id );
      el.value = e.val;
    }
    );

Shiny.addCustomMessageHandler("setStyle",
    function(e) {
      mxSetStyle(e.group,e.style,e.layer,false);
    }
);

Shiny.addCustomMessageHandler("addCss",
    function(fileName) {
      $("head").append("<link>");
      var css = $("head").children(":last");
      css.attr({
        rel:  "stylesheet",
        type: "text/css",
        href: fileName
      });
    }
    );


Shiny.addCustomMessageHandler("updateText",
    function(m) {
      el = document.getElementById(m.id);
      if( typeof el != "undefined" && el !== null ){
        el.innerHTML=b64_to_utf8(m.txt.toString());
        if(m.addId){
          setUniqueItemsId();
        }
      }
    }
    );



Shiny.addCustomMessageHandler("mapUiUpdate",
    function(message){
      updateMapElement();
    }
    );




LeafletWidget.methods.setZoomOptions = function(buttonOptions,removeButton){
  z = document.querySelector(".leaflet-control-zoom");
  if( typeof buttonOptions !== "undefined" ){
    if( typeof(z) !== "undefined" && z !== null){
      z.parentNode.removeChild(z);
    }
    if(!removeButton){
      zC = L.control.zoom(buttonOptions);
        zC.addTo(this);
    }
  }
};
});


