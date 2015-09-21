
Shiny.addCustomMessageHandler("jsCode",
    function(message) {
      eval(message.code);
    }
    );

Shiny.addCustomMessageHandler("mapUiUpdate",
    function(message){
        console.log("UPDATE MAP SECTION"); 
        updateMapElement();
    }
    );


$(function() {
updateMapElement();
});



var mxPanelMode = {};
var leafletvtGroup = {};

updateMapElement = function(){
  console.log($("#map-left"));
  $("#btnStopMapScroll").click(function(){
        var idSection = "#sectionMap";
        idScroll = "#map-left";
        idBtn = "#btnStopMapScroll";

        var $document = $(document),
        $body = $('body'),
        $scrolable = $(idScroll);

        if(toggleScrollMap){
          window.location = idSection ;  
          $body.addClass('noscroll');
          $scrolable.on({
            'mouseenter': function () {
              // add hack class to prevent workspace scroll when scroll outside
              $body.addClass('noscroll');
            },
            'mouseleave': function () {
              // remove hack class to allow scroll
              $body.removeClass('noscroll');
            }
          });
          $(idBtn).html("<i class='fa fa-lock'>");
        }else{

          $body.removeClass('noscroll');
          $(idScroll).off('mouseenter');
          $(idScroll).off('mouseleave');
          $(idBtn).html("<i class='fa fa-unlock'>");
        }
        toggleScrollMap = !toggleScrollMap ;
      });


      /* collapse handle */
      var idViews = "#map-left",
      idBtnViews = "#btnViewsCollapse",
      idInfo = "#info-box" ,
      idBtnInfo = "#btnInfoClick",
      idTitlePanel = "#titlePanelMode",
      /*  classLegends = ".info",*/

      toggleScrollMap = true,
      toggleCollapseViews = true,
      toggleCollapseInfoClick = true;

      /* toggle info box panel  */
      $(idBtnViews).click(function(){
        if(toggleCollapseViews){
          $(idViews).animate({left:"-360px"},500);
          $(idInfo).animate({left:"90px"},500);
          $(idBtnViews).html("<i class='fa fa-angle-double-right'>");
          $(idTitlePanel).css({opacity:"0"});
        }else{ 
          $(idViews).animate({left:"0px"},500);
          $(idInfo).animate({left:"450px"},500);
          $(idBtnViews).html("<i class='fa fa-angle-double-left'>");
          $(idTitlePanel).css({opacity:"1"});
        }
        toggleCollapseViews = !toggleCollapseViews;
      });


      /* toggle info panel and lengends */
      $(idBtnInfo).click(function(){
        if(toggleCollapseInfoClick){
          $(idInfo).animate({height:"200px"},500);
          /* $(classLegends).animate({right:"0px"},500);*/
        }else{ 
          $(idInfo).animate({height:"0px"},500);
          /* $(classLegends).animate({right:"-250px"},500);*/
        }
        toggleCollapseInfoClick = !toggleCollapseInfoClick;
      });




}










/*
   $( '#sectionMap.stopScroll' ).bind( 'mousewheel DOMMouseScroll', function ( e ) {
   var e0 = e.originalEvent,
   delta = e0.wheelDelta || -e0.detail;

   this.scrollTop += ( delta < 0 ? 1 : -1 ) * 30;
   e.preventDefault();
   });

*/

/*
// Closes the sidebar menu
$("#menu-close").click(function(e) {
console.log('click');
e.preventDefault();
$("#sidebar-wrapper").toggleClass("active");
});

// Opens the sidebar menu
$("#menu-toggle").click(function(e) {
e.preventDefault();
$("#sidebar-wrapper").toggleClass("active");
});

// Scrolls to the selected menu item on the page
$(function() {
$('a[href*=#]:not([href=#])').click(function() {
if (location.pathname.replace(/^\//, '') == this.pathname.replace(/^\//, '') || location.hostname == this.hostname) {

var target = $(this.hash);
target = target.length ? target : $('[name=' + this.hash.slice(1) + ']');
if (target.length) {
$('html,body').animate({
scrollTop: target.offset().top
}, 1000);
return false;
}
}
});
});

*/
