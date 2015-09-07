
Shiny.addCustomMessageHandler("jsCode",
    function(message) {
      eval(message.code);
    }
    );


var mxPanelMode = {};
var leafletvtGroup = {};
//
//function $$(selector, context) {
//  context = context || document;
//  var elements = context.querySelectorAll(selector);
//  return Array.prototype.slice.call(elements);
//} 

$( document ).ready(function( $ ) {
  // don't display label for selec input
  //$("label[for='selectCountry']").css('display',"none");

  // link inside dropdown problem
  //http://stackoverflow.com/questions/23057321/links-inside-twitter-bootstrap-dropdown-menu-wont-work
  $('.dropdown').find('a').on('click', function() {
    href = $(this).attr('href');
    if(href != "#")window.location = href;
  });


  $( "#menuCountry" ).click(function( event ) {
    event.preventDefault();
  });

  /* toggle scroll on map panel*/
//   $('.scrollable').bind('DOMMouseScroll mousewheel', function(ev) {
//        var $this = $(this),
//        scrollTop = this.scrollTop,
//        scrollHeight = this.scrollHeight,
//        height = $this.height(),
//        delta = ev.originalEvent.wheelDelta,
//        up = delta > 0;
//
//        var prevent = function() {
//          ev.stopPropagation();
//          ev.preventDefault();
//          ev.returnValue = false;
//          return false;
//        }
//
//        if (!up && -delta > scrollHeight - height - scrollTop) {
//          // Scrolling down, but this will take us past the bottom.
//          $this.scrollTop(scrollHeight);
//          return prevent();
//        } else if (up && delta > scrollTop) {
//          // Scrolling up, but this will take us past the top.
//          $this.scrollTop(0);
//          return prevent();
//        }
//      });

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



// 
//
//  $("#btnStopMapScroll").click(function( ){
//    var idMap = "#sectionMap";
//    var idBtn = "#btnStopMapScroll";
//    if(toggleScrollMap){
//      window.location = idMap ;
//      $(idMap).bind('mousewheel DOMMouseScroll', function ( e ) {
//        var e0 = e.originalEvent,
//        delta = e0.wheelDelta || -e0.detail;
//        this.scrollTop += ( delta < 0 ? 1 : -1 ) * 30;
//        e.preventDefault();
//      });
//      $(idBtn).html("<i class='fa fa-lock'>");
//    }else{
//      $(idMap).unbind('mousewheel DOMMouseScroll ');
//      $(idBtn).html("<i class='fa fa-unlock'>");
//    };
//   toggleScrollMap = !toggleScrollMap ;
//  });
//



  



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




  });


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
