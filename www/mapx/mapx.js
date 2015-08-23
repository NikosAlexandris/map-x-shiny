
Shiny.addCustomMessageHandler("jsCode",
    function(message) {
      console.log(message);
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
    console.log(href); 
    if(href != "#")window.location = href;
  });


  $( "#menuCountry" ).click(function( event ) {
    event.preventDefault();
  });
});








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
