/* temporary object to hold ui and style state*/
var leafletvtId = {};
var leafletvtSty = {};
var mxPanelMode = {};


//
// Shiny binding 
// 
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

// 
// when document ready, apply the  map panel element interaction functions.
// 
$(function() {
  updateMapElement();
});

//
// Update map panel elements interaction 
//
function updateMapElement(){
  //
  //  map panel lock button 
  //
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
  // Panel animation
  //
  var idViews = "#map-left",
  idBtnViews = "#btnViewsCollapse",
  idInfo = "#info-box" ,
  idBtnInfo = "#btnInfoClick",
  idTitlePanel = "#titlePanelMode",

  // set default state
  toggleScrollMap = true,
  toggleCollapseViews = true,
  toggleCollapseInfoClick = true;

  // add a click function to btn collapse views 
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

  // add a click function to btn info panel
  $(idBtnInfo).click(function(){
    if(toggleCollapseInfoClick){
      $(idInfo).animate({height:"200px"},500);
    }else{ 
      $(idInfo).animate({height:"0px"},500);
    }
    toggleCollapseInfoClick = !toggleCollapseInfoClick;
  });
}

//
// check if given id is checked 
//
function isCheckedId(id){
  var el = document.getElementById(id);
  if( el === null ){
    return false;
  } else {
    return el.checked === true;    
  }
}

//
// check if checked input's value is the given id 
//
function isCheckedValue(id){
  var checkedId = $("input:checked").val();
  return checkedId == id;

}

//
// hide panel if given item id is not checked 
//
function toggleOptions(id,idOption,idOptionPanel) {
  if($('input[value='+id+']').prop("checked")){
    $('#'+idOption).css("display","block");
    $('#'+idOptionPanel).css("display","block");
  }else{ 
    $('#'+idOption).css("display","none");
    $('#'+idOptionPanel).css("display","none");
  }

}

//
// change opacity for given layer id
//
function setOpacityForId(id,opacity){
  if(typeof(leafletvtId[id]) !== "undefined" ){
    leafletvtId[id].setOpacity(opacity);
  }
}

//
// copy the original style of the layer, set min and max date and update style 
//
function setRange(id,min,max){
  leafletvtSty = leafletvtId[id].vtStyle;
  leafletvtSty.mxDateMin[0] = min;
  leafletvtSty.mxDateMax[0] = max;
  leafletvtId[id].setStyle(updateStyle);
}


//
// If a filter column and value is given, set style options and update style with filter function 
//
function setFilter(layer,id,column,value){
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

//
// handle style when filter by column and value is requested 
//
function updateStyleFilter(feature){
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

  if( typeof(value)=="undefined"){
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
  }
  return style;
}

//
// Default style if no colors are needed. e.g. if we need to show a filtered views.
//
function defaultStyle(feature) {
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
  }
  return style;
}


//
// Update style and apply time slider filtering if data has date columns.
//
function updateStyle(feature) {
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
      style.radius = leafletvtSty.size[0];
      selected.color = 'rgba(255,255,0,0.5)';
      selected.radius = 6;
      break;
    case 2: //'LineString'
      style.color = dataCol;
      style.size = leafletvtSty.size[0];
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
  }
  return style;
}

