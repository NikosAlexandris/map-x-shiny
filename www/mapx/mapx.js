/* temporary object to hold ui and style state*/
var leafletvtId = {};
var mxPanelMode = {};
var mxConfig = {
  mapPanelMode : null,
  mapInfoBox : {
    id : "#info-box",
    enabled : true,
    height : "0px",
    defaultHeightCollapsed : "0px",
    defaultHeightEnabled : "200px",
    toggle : function(height,enabled){
      if(enabled === false){
        this.enabled = false; 
      }
      if(enabled === true){
        this.enabled = true;
      }
      if(this.enabled){
        if(typeof height !== "undefined"){
          this.height = height;
        }else{

          this.height = this.defaultHeightEnabled;
        }
        $(this.id).animate({height:this.height},500);
      }else{ 
        $(this.id).animate({height:this.defaultHeightCollapsed},500);
      }
      console.log("mxConfig info box changes: height="+this.height+" enabled="+this.enabled);
      this.enabled =! this.enabled;
    }
  }
};

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
    idScroll = "#map-left,#info-box-container,#mapxMap";
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
    mxConfig.mapInfoBox.toggle();
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
    $('#'+idOption).css("display","inline-block");
    $('#'+idOptionPanel).css("display","block");
  }else{ 
    $('#'+idOption).css("display","none");
    $('#'+idOptionPanel).css("display","none");
  }
}

function vtPreview(id){
    Shiny.onInputChange("viewsFromPreview",id);
}


function vtPreviewHandler(id,view,timeOut){
  timeOut = parseInt(timeOut);
  var timer;

  $('#'+id).on({
    'mouseover': function () {
      timer = setTimeout(function () {
        Shiny.onInputChange("viewsFromPreview",view);
      }, timeOut);
    },
    'mouseout' : function () {
      Shiny.onInputChange("viewsFromPreview","");
      clearTimeout(timer);
    }
  });

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
// handle style when filter by column and value is requested 
//

function mxSetFilter(layer,id,column,value){

  if(typeof(leafletvtId[id]) == "undefined")return;

  var vtStyle = leafletvtId[id].vtStyle;

  if(value.length>0){
    value = value.split(",");
    var d = {};
    d.id=id;
    d.column=column;
    d.value=value;
    d.layer=layer;
    Shiny.onInputChange("filterLayer",d);
    // update style
    vtStyle.mxFilterColumn = column;
    vtStyle.mxFilterValue = value;

    var sty = function(feature){
      var style = {};
      var selected = style.selected = {};
      var  type = feature.type,
      defaultColor = 'rgba(0,0,0,0)',
      dataCol = defaultColor,
      val = feature.properties[vtStyle.dataColum[0]], 
      filterColumn = vtStyle.mxFilterColumn,
      filterValue = vtStyle.mxFilterValue,
      value = feature.properties[filterColumn],
      skip = false;

      if( typeof(value)=="undefined"){
        return;
      }

      if( 
          typeof(filterColumn) != "undefined" && 
          typeof(filterValue) != "undefined" && 
          typeof(value) != "undefined" 
        ){
        if(filterValue.indexOf(value)==-1){
          skip = true;
        }
      }
      if(skip){
        return;
      }else{
        if( typeof(val) != 'undefined'){ 
          dataCol = 'rgba(255,0,0,0.8)';
          if(typeof(dataCol) == 'undefined'){
            dataCol = defaultColor;
          }
        }
      }

      switch (type) {
        case 1: //'Point'
          style.color = dataCol;
          style.radius = vtStyle$size[0];
          selected.color = 'rgba(255,255,0,0.5)';
          selected.radius = 6;
          break;
        case 2: //'LineString'
          style.color = dataCol;
          style.size = vtStyle$size[0];
          selected.color = 'rgba(255,25,0,0.5)';
          selected.size = vtStyle.size[0];
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
    };
  leafletvtId[id].setStyle(sty,layer+"_geom");
  }else{
    mxSetStyle(id,vtStyle,layer,true);
  }
}

//
// Set time sldider filter
//
function mxSetRange(id,min,max,lay){
  // copy style
  vtStyle = leafletvtId[id].vtStyle;
  // create function to apply
  var sty = function(feature) {
    var style = {};
    var selected = style.selected = {};
    var  type = feature.type,
    defaultColor = 'rgba(0,0,0,0)',
    dataCol = defaultColor,
    val = feature.properties[vtStyle.dataColum[0]],
    dateStyleMin = min,
    dateStyleMax = max,
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
        dataCol = hex2rgb(vtStyle.colorsPalette[val][0],vtStyle.opacity[0]);
        if(typeof(dataCol) == 'undefined'){
          dataCol = defaultColor;
        }
      }
    }

    switch (type) {
      case 1: //'Point'
        style.color = dataCol;
        style.radius = vtStyle.size[0];
        selected.color = 'rgba(255,255,0,0.5)';
        selected.radius = 6;
        break;
      case 2: //'LineString'
        style.color = dataCol;
        style.size = vtStyle.size[0];
        selected.color = 'rgba(255,25,0,0.5)';
        selected.size = vtStyle.size[0];
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
  };

  console.log("Set time slider style for "+id);
  leafletvtId[id].setStyle(sty,lay+"_geom");
}


// 
// mx set style
//

function mxSetStyle(id,vtStyle,lay,overwrite){
// check if the provided style is the same as this already applied  
  if(!overwrite){
    if(vtStyle == leafletvtId[id].vtStyle){
      if(vtStyle.dataColumn[0] == leafletvtId[id].vtStyle.dataColumn[0]){
      }
      console.log("Identical style already exists for id="+id);
        return;
    }
  }
  // save style to leafletvtId object
  leafletvtId[id].vtStyle = vtStyle;
  // create function to apply
  var sty = function(feature) {
    var style = {};
    var selected = style.selected = {};
    var  type = feature.type,
    defaultColor = 'rgba(0,0,0,0)',
    dataCol = defaultColor,
    val = feature.properties[vtStyle.dataColum[0]];
    if( typeof(val) != 'undefined'){ 
      // extract color by val
      col = vtStyle.colorsPalette[val];
      if(typeof(col) == "undefined"){
        console.log("Error. No color found for "+val);
      }
      dataCol = hex2rgb(col[0],vtStyle.opacity[0]);
      if(typeof(dataCol) == 'undefined'){
        console.log("Error. dataCol undefined for "+val+"set default color");
        dataCol = defaultColor;
      }
    }
    switch (type) {
      case 1: //'Point'
        style.color = dataCol;
        style.radius = vtStyle.size[0];
        selected.color = 'rgba(255,255,0,0.5)';
        selected.radius = 6;
        break;
      case 2: //'LineString'
        style.color = dataCol;
        style.size = vtStyle.size[0];
        selected.color = 'rgba(255,25,0,0.5)';
        selected.size = vtStyle.size[0];
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
  };

  console.log("Apply style function for "+id);
  leafletvtId[id].setStyle(sty,lay+"_geom");
}


//
// Update style and apply time slider filtering if data has date columns.
//
//function updateStyle(feature) {
//  var style = {};
//  var selected = style.selected = {};
//  var  type = feature.type,
//  defaultColor = 'rgba(0,0,0,0)',
//  dataCol = defaultColor,
//  val = feature.properties[leafletvtSty.dataColum[0]],
//  dateStyleMin = leafletvtSty.mxDateMin[0],
//  dateStyleMax = leafletvtSty.mxDateMax[0],
//  dateFeatStart = feature.properties.mx_date_start,
//  dateFeatEnd = feature.properties.mx_date_end,
//  d = []; 
//  // skip = set feature style to default(transparent)
//  var skip = false ;
//  // if 
//  var hasDate = false ;
//
//  if( typeof(dateFeatEnd) != "undefined" && typeof(dateFeatStart) != "undefined" ){
//    hasDate = true;
//    d.push(
//        dateStyleMin,
//        dateStyleMax,
//        dateFeatStart,
//        dateFeatEnd
//        );
//    for(var i = 0; i<4; i++){
//      if ( typeof(d[i]) == 'undefined' || d[i] === null){
//        hasDate = false ;
//      }
//    }
//    if(hasDate){
//      if(d[2] < d[0] || d[3] > d[1]){
//        skip = true ;
//      }
//    }
//  }
//
//
//
//  if(skip){
//    return;
//  }else{
//    if( typeof(val) != 'undefined'){ 
//      dataCol = hex2rgb(leafletvtSty.colorsPalette[val][0],leafletvtSty.opacity[0]);
//      if(typeof(dataCol) == 'undefined'){
//        dataCol = defaultColor;
//      }
//    }
//  }
//
//
//  switch (type) {
//    case 1: //'Point'
//      style.color = dataCol;
//      style.radius = leafletvtSty.size[0];
//      selected.color = 'rgba(255,255,0,0.5)';
//      selected.radius = 6;
//      break;
//    case 2: //'LineString'
//      style.color = dataCol;
//      style.size = leafletvtSty.size[0];
//      selected.color = 'rgba(255,25,0,0.5)';
//      selected.size = leafletvtSty.size[0];
//      break;
//    case 3: //'Polygon'
//      style.color = dataCol;
//      style.outline = {
//        color: dataCol,
//        size: 1
//      };
//      selected.color = 'rgba(255,0,0,0)';
//      selected.outline = {
//        color: 'rgba(255,0,0,0.9)',
//        size: 1
//      };
//      break;
//  }
//  return style;
//}
//
// still used bx server/analysis
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



LeafletWidget.methods.setZoomOptions = function(buttonOptions,removeButton){
  z = document.querySelector(".leaflet-control-zoom");
  if( typeof buttonOptions !== "undefined" ){
    if( typeof(z) !== "undefined" && z !== null){
      z.parentNode.removeChild(z);
    }
    if(!removeButton){
      zC = L.control.zoom(buttonOptions)
        zC.addTo(this);
    }
  }
};



//
//
///
//// Default style if no colors are needed. e.g. if we need to show a filtered views.
////
//
//function applyStyleFilter(id,vtStyle,lay){
//  console.log("Apply style")
//  // shortcut to applied style
//  leafletvtId[id].vtStyle = vtStyle;
//  // create function to apply
//  var sty = function(feature) {
//    var style = {};
//    var selected = style.selected = {};
//    var  type = feature.type,
//    defaultColor = 'rgba(0,0,0,0)',
//    dataCol = defaultColor,
//    val = feature.properties[vtStyle.dataColum[0]],
//    dateStyleMin = vtStyle.mxDateMin[0],
//    dateStyleMax = vtStyle.mxDateMax[0],
//    dateFeatStart = feature.properties.mx_date_start,
//    dateFeatEnd = feature.properties.mx_date_end,
//    d = []; 
//    // skip = set feature style to default(transparent)
//    var skip = false ;
//    // if 
//    var hasDate = false ;
//
//    if( typeof(dateFeatEnd) != "undefined" && typeof(dateFeatStart) != "undefined" ){
//      hasDate = true;
//      d.push(
//          dateStyleMin,
//          dateStyleMax,
//          dateFeatStart,
//          dateFeatEnd
//          );
//      for(var i = 0; i<4; i++){
//        if ( typeof(d[i]) == 'undefined' || d[i] === null){
//          hasDate = false ;
//        }
//      }
//      if(hasDate){
//        if(d[2] < d[0] || d[3] > d[1]){
//          skip = true ;
//        }
//      }
//    }
//
//
//
//    if(skip){
//      return;
//    }else{
//      if( typeof(val) != 'undefined'){ 
//        dataCol = hex2rgb(vtStyle.colorsPalette[val][0],vtStyle.opacity[0]);
//        if(typeof(dataCol) == 'undefined'){
//          dataCol = defaultColor;
//        }
//      }
//    }
//
//
//    switch (type) {
//      case 1: //'Point'
//        style.color = dataCol;
//        style.radius = vtStyle.size[0];
//        selected.color = 'rgba(255,255,0,0.5)';
//        selected.radius = 6;
//        break;
//      case 2: //'LineString'
//        style.color = dataCol;
//        style.size = vtStyle.size[0];
//        selected.color = 'rgba(255,25,0,0.5)';
//        selected.size = vtStyle.size[0];
//        break;
//      case 3: //'Polygon'
//        style.color = dataCol;
//        style.outline = {
//          color: dataCol,
//          size: 1
//        };
//        selected.color = 'rgba(255,0,0,0)';
//        selected.outline = {
//          color: 'rgba(255,0,0,0.9)',
//          size: 1
//        };
//        break;
//    }
//    return style;
//  }
//
//
//  leafletvtId[id].setStyle(sty,lay+"_geom");
//}
//
//
////
//// copy the original style of the layer, set min and max date and update style 
////
//function setRange(id,min,max){
//  var leafletvtSty = leafletvtId[id].vtStyle;
//  leafletvtSty.mxDateMin[0] = min;
//  leafletvtSty.mxDateMax[0] = max;
//  leafletvtId[id].setStyle(updateStyle);
//}
//
//
//
//
