var leafletvtId = {};
var leafletvtSty = {};

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

updateMapElement = function(){
  $("#btnStopMapScroll").click(function(){
    var idSection = "#sectionMap";
    idScroll = "#map-left";
    idBtn = "#btnStopMapScroll";

    var $document = $(document),
    $body = $('body'),
    $scrolable = $(idScroll);

    if(toggleScrollMap){
      $('html, body').stop().animate({
        scrollTop: $(idSection).offset().top - $(".navbar-header").height() 
      }, 100, 'easeOutQuad');
      //window.location = idSection ;  
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
};


isCheckedId = function(id){
  var el = document.getElementById(id);
  if( el === null ){
    return false;
  } else {
    return el.checked === true;    
  }
};

isCheckedValue = function(id){
  $("input:checked").val()==id;
};


function toggleOptions(id,idOption,idOptionPanel) {
  if($('input[value='+id+']').prop("checked")){
    $('#'+idOption).css("display","block");
      $('#'+idOptionPanel).css("display","block");
  }else{ 
    $('#'+idOption).css("display","none");
      $('#'+idOptionPanel).css("display","none");
  }

};


setOpacityForId = function(id,opacity){
  if(typeof(leafletvtId[id]) !== "undefined" ){
    leafletvtId[id].setOpacity(opacity);
  }
};


setRange = function(id,min,max){
  leafletvtSty = leafletvtId[id].vtStyle;
  leafletvtSty.mxDateMin[0] = min;
  leafletvtSty.mxDateMax[0] = max;
  leafletvtId[id].setStyle(updateStyle);
};




setFilter = function(layer,id,column,value){
  if(typeof(leafletvtId[id]) == "undefined")return;
  if(value !="[ NO FILTER ]"){
    var d = {};
    d.id=id;
    d.column=column;
    d.value=value;
    d.layer=layer;
    Shiny.onInputChange("filterLayer",d);
    leafletvtSty = leafletvtId[id].vtStyle;
    leafletvtSty.mxFilterColumn = column;
    leafletvtSty.mxFilterValue = value;

    leafletvtId[id].setStyle(updateStyleFilter);

  }else{ 
    leafletvtId[id].setStyle(updateStyle);
  }
}

updateStyleFilter = function (feature) {
  var style = {};
  var selected = style.selected = {};
  var  type = feature.type,
  defaultColor = 'rgba(0,0,0,0)',
  dataCol = defaultColor,
  val = feature.properties[leafletvtSty.dataColum[0]], 
  filterColumn = leafletvtSty.mxFilterColumn,
  filterValue = leafletvtSty.mxFilterValue,
  value = feature.properties[filterColumn],
  skip = false;
 
  if(typeof(value)=="undefined"){
  return;
  }
  
  if( typeof(filterColumn) != "undefined" && typeof(filterValue) != "undefined" && typeof(value) != "undefined" ){
    if(filterValue!=value){
    skip = true;
    }
  }
  if(skip){
    return;
  }else{
    if( typeof(val) != 'undefined'){ 
 //dataCol = hex2rgb(leafletvtSty.colorsPalette[val][0],leafletvtSty.opacity[0]);
      dataCol = 'rgba(255,0,0,1)';
      if(typeof(dataCol) == 'undefined'){
        dataCol = defaultColor;
      }
    }
  }


  switch (type) {
    case 1: //'Point'
      style.color = dataCol;
      style.radius = leafletvtSty$size[0];
      selected.color = 'rgba(255,255,0,0.5)';
      selected.radius = 6;
      break;
    case 2: //'LineString'
      style.color = dataCol;
      style.size = leafletvtSty$size[0];
      selected.color = 'rgba(255,25,0,0.5)';
      selected.size = leafletvtSty.size[0];
      break;
    case 3: //'Polygon'
      style.color = dataCol;
      style.outline = {
        color: 'rgba(0,0,0,1)',
        size: 1
      };
      selected.color = 'rgba(255,0,0,0)';
      selected.outline = {
        color: 'rgba(255,0,0,0.9)',
        size: 1
      };
      break;
  };
  return style;
};



defaultStyle = function(feature) {
  var style = {};
  var selected = style.selected = {};
  var type = feature.type;
  var dataCol = 'rgba(255,0,0,0.8)';
  var size = 1;

  switch (type) {
    case 1: //'Point'
      //style.color = 'rgba(49,79,79,1)';
      style.color = dataCol;
      style.radius = size;
      selected.color = 'rgba(255,255,0,0.5)';
      selected.radius = 6;
      break;
    case 2: //'LineString'
      //style.color = 'rgba(161,217,155,0.8)';
      style.color = dataCol;
      style.size = size;
      selected.color = 'rgba(255,25,0,0.5)';
      selected.size = size;
      break;
    case 3: //'Polygon'
      style.color = dataCol;
      style.outline = {
        color: 'rgba(0,0,0,1)',
        size: 1
      };
      selected.color = 'rgba(255,0,0,0.3)';
      selected.outline = {
        color: 'rgba(255,0,0,1)',
        size: size
      };
      break;
  };
  return style;
}


updateStyle = function (feature) {
  var style = {};
  var selected = style.selected = {};
  var  type = feature.type,
  defaultColor = 'rgba(0,0,0,0)',
  dataCol = defaultColor,
  val = feature.properties[leafletvtSty.dataColum[0]],
  dateStyleMin = leafletvtSty.mxDateMin[0],
  dateStyleMax = leafletvtSty.mxDateMax[0],
  dateFeatStart = feature.properties.mx_date_start,
  dateFeatEnd = feature.properties.mx_date_end,
  d = []; 

  // skip = set feature style to default(transparent)
  var skip = false ;
  // if 
  var hasDate = false ;

  if( typeof(dateFeatEnd) != "undefined" && typeof(dateFeatStart) != "undefined" ){
    hasDate = true;
    d.push(
        dateStyleMin,
        dateStyleMax,
        dateFeatStart,
        dateFeatEnd
        );
    for(var i = 0; i<4; i++){
      if ( typeof(d[i]) == 'undefined' || d[i] === null){
        hasDate = false ;
      }
    }
    if(hasDate){
      if(d[2] < d[0] || d[3] > d[1]){
        skip = true ;
      }
    }
  }



  if(skip){
    return;
  }else{
    if( typeof(val) != 'undefined'){ 
      dataCol = hex2rgb(leafletvtSty.colorsPalette[val][0],leafletvtSty.opacity[0]);
      if(typeof(dataCol) == 'undefined'){
        dataCol = defaultColor;
      }
    }
  }


  switch (type) {
    case 1: //'Point'
      style.color = dataCol;
      style.radius = leafletvtSty$size[0];
      selected.color = 'rgba(255,255,0,0.5)';
      selected.radius = 6;
      break;
    case 2: //'LineString'
      style.color = dataCol;
      style.size = leafletvtSty$size[0];
      selected.color = 'rgba(255,25,0,0.5)';
      selected.size = leafletvtSty.size[0];
      break;
    case 3: //'Polygon'
      style.color = dataCol;
      style.outline = {
        color: dataCol,
        size: 1
      };
      selected.color = 'rgba(255,0,0,0)';
      selected.outline = {
        color: 'rgba(255,0,0,0.9)',
        size: 1
      };
      break;
  };
  return style;
};

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
          $(this).html(text)
        }else{
          $(this).attr(attribute, text)
        }
      }
      )
};

