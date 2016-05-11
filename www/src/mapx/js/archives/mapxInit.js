

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
//Shiny.onInputChange("documentIsReady",new Date());
// set language
//Shiny.onInputChange("cookiesLanguage",Cookies.get("lang"));
// set country
//Shiny.onInputChange("cookiesCountry",Cookies.get("country"));





