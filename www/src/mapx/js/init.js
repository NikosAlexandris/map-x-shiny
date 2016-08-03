





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

  Shiny.addCustomMessageHandler("mxCleanViewsMenu",
      function(e) {

        var viewsCheck =  document.getElementsByName("viewsFromMenu");

        for( var i = 0; i < viewsCheck.length; i++ ){
          var item = viewsCheck[i];
          if( item.checked === true ){
            item.click();
            /* var legend = document.getElementsByClassName( item.value + "_legends")[0];*/
            //if( typeof(legend) !== "undefined" ) {
            //debugger;
            //legend.remove();
            //}
            /*}*/
        }
      }
      }
      );
  });




