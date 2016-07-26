





// When document is ready
$( document ).ready(function() {
  // Closes the Responsive Menu on Menu Item Click
  $('.navbar-collapse ul li a').click(function() {
    $('.navbar-toggle:visible').click();
  });

  // background selector
  changeBg();

  // story map container action
  var storyCont = $("#mapLeftScroll");
  storyCont.on("scroll",updateStoryMaps);


  $('#storyMapModal').draggable({ 
    handle:'#storyMapModalHandle',
    containment: '#sectionMap'
  });

/*  // show or hide country selection */
  //var countryChoice = document.getElementById("navBarCountryChoice");  
  //countryChoice.onmouseover = function(){
    //classRemove('selectCountryPanel','mx-hide'); 
    //classAdd('countryTitle','mx-hide'); 
  //};
  //countryChoice.onmouseout = function(){
    //classAdd('selectCountryPanel','mx-hide');
    //classRemove('countryTitle','mx-hide');
  //};


});




