



var storyMapLayer = {store:[]};

/* Object to hold ui and style state*/
var leafletvtId = {};

// https://davidwalsh.name/javascript-debounce-function
// Returns a function, that, as long as it continues to be invoked, will not
// be triggered. The function will be called after it stops being called for
// N milliseconds. If `immediate` is passed, trigger the function on the
// leading edge, instead of the trailing.
function debounce(func, wait, immediate) {
  var timeout;
  return function() {
    var context = this, args = arguments;
    var later = function() {
      timeout = null;
      if (!immediate) func.apply(context, args);
    };
    var callNow = immediate && !timeout;
    clearTimeout(timeout);
    timeout = setTimeout(later, wait);
    if (callNow) func.apply(context, args);
  };
}


// got to anchor without changing url
function goTo(id){
  var dest = document.getElementById(id) ;
  if(typeof(dest) != "undefined"){
    if(id != "sectionTop"){
      classAdd("navbarTop","top-nav-collapse");
    }else{
      classRemove("navbarTop","top-nav-collapse");
    }
    dest.scrollIntoView(false);
  }
  return false;
}


function enableSection(id){
  var dest = document.getElementById(id) ;
  var sections = document.getElementsByClassName("mx-section-container");

    if(typeof(id) != "undefined"){

      for(s=0;s<sections.length;s++){
        var i = sections[s].id;
        if(i == id){
          // Show
          classRemove(i,"mx-hide");
          classAdd(i,"mx-show");
        }else{
          // Hide
          classRemove(i,"mx-show");
          classAdd(i,"mx-hide");
        }
      }

      if(id != "sectionTop"){
        classAdd("navbarTop","top-nav-collapse");
      }else{
        classRemove("navbarTop","top-nav-collapse");
      }
    }
  return false;


}

function enablePanelMode(id,title){
  /* Which element contain the ui to enable */
  var dest = document.getElementById(id) ;
  /* Get all section containing a panel mode*/
  var sections = document.getElementsByClassName("mx-panel-mode");
  /* Get element to set the title */
  var elTitle = document.getElementById("titlePanelMode");
  /* In all case, show the left panel */
  classRemove('mapLeftPanel',"mx-hide");
  /* Logic : enable selected, disable others*/
  if(typeof(id) != "undefined"){
    elTitle.textContent=title;
    for(s=0;s<sections.length;s++){
      var i = sections[s].id;
      if(i == id){
        // Show
        classRemove(i,"mx-hide");
        classAdd(i,"mx-show");
      }else{
        // Hide
        classRemove(i,"mx-show");
        classAdd(i,"mx-hide");
      }
    }
    /* Send the id to server */
    Shiny.onInputChange("mxPanelMode", { 
      id:id
    }
    );
  }
}

function classAdd(id,cl){
  var el = document.getElementById(id),
  oldCl = el.className.split(" "),
  idx = oldCl.indexOf(cl),
  hasClass = idx > -1;
  if(!hasClass){
    oldCl.push(cl);
    el.className = oldCl.join(" ");
  }
}

function classRemove(id,cl){
  var el = document.getElementById(id),
  oldCl = el.className.split(" "),
  idx = oldCl.indexOf(cl),
  hasClass = idx > -1;
  if(hasClass){
    oldCl.pop(idx);
    el.className = oldCl.join(" ");
  }
}

function classToggle(id,cl) {
  if(typeof(cl)=="undefined"){
    cl = "mx-hide";
  }
  var el = document.getElementById(id),
  oldCl = el.className.split(" "),
  idx = oldCl.indexOf(cl),
  hasClass = idx>-1 ;

  if(hasClass){
    oldCl.pop(idx);
  }else{
    oldCl.push(cl);
  }
  el.className = oldCl.join(" ");
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

// change background each times
function changeBg(){
  bgClasses = ["mx-top-bg-1","mx-top-bg-2","mx-top-bg-3"];
  var bgClass = bgClasses[Math.floor(Math.random()*bgClasses.length)];
  $("#sectionTop").addClass(bgClass);
}

// request zoom to extent
function  mxRequestZoom(viewId){
  var trigger = new Date();
  Shiny.onInputChange("mxRequestZoom", { 
    id:viewId, 
  }
  );
}


// decode b64 and keep utf8 formating
// taken from http://stackoverflow.com/questions/30106476/using-javascripts-atob-to-decode-base64-doesnt-properly-decode-utf-8-strings
function b64_to_utf8( str ) {
  str = str.replace(/\s/g, '');    
  return decodeURIComponent(escape(window.atob( str )));
}
function utf8_to_b64( str ) {
  return window.btoa(unescape(encodeURIComponent( str )));
}

//function toggleDropDown(id) {
  //document.getElementById(id).classList.toggle("mx-dropdown-show");
/*}*/



// http://stackoverflow.com/questions/1349404/generate-a-string-of-5-random-characters-in-javascript
function makeid(){
  var text = "";
  var possible = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789";

  for( var i=0; i < 5; i++ )
    text += possible.charAt(Math.floor(Math.random() * possible.length));

  return text;
}


// post proc functions
function setUniqueItemsId(){
  storyMapLayer = {store:[]};
  $(".mx-story-section").each(function(){ 
    $(this).attr('id',makeid());
  }
  );
}
// update text
//


  // story map handler
function  updateStoryMaps_orig(){

    // var containerOffset =  $("#mxStoryContainerPreview").offset().top;

    var limitObj = $("#mxStoryLimitTrigger");
    var limitPos = limitObj.offset().top + limitObj.height();

    $(".mx-story-section").each(
        function(){

          var $item = $(this);
          var enable = false,
          id = $item.prop('id'),
          vId = $item.attr("mx-map-id"),
          vExt = JSON.parse($item.attr("mx-map-extent")),
          vTit = $item.attr('mx-map-title'),
          prevData = storyMapLayer[id],
          prevState = false,
          onView = false,
          hasLayer = false,
          vOpa = 1, 
          out = {};

          if(prevData === undefined){
            storyMapLayer[id] = {};
          }else{

            if(typeof prevData.enable !== "undefined" ){
              prevState = prevData.enable;
            }

            tDist = limitPos - $item.offset().top;
            bDist = limitPos - ($item.offset().top + $item.height());

            if ( tDist > 0 && bDist < 0){
              onView = true;
            }


            if(onView !== prevState){
              storyMapLayer[id].enable = onView;
              
              /*
              set class for text when view state change
              */
              if(onView){
                storyMapLayer.store.push(vId);
                $item.removeClass("mx-story-dimmed");
              }else{
                storyMapLayer.store.pop(vId);
                $item.addClass("mx-story-dimmed");
              }

              /* 
                 find a way to keep in synch view from menu and story map view :
                 If a story map is not finished, view will remain, as the user can
                 want to quit and return where he/she was. 

                 old method : use a layer store and trigger an shiny event
                 new method : simply trigger a click in the menu

*/

              /* check if map already has the layer */

              if ( typeof leafletvtId[vId] !== "undefined" ){
                hasLayer = leafletvtId[vId].map.hasLayer(leafletvtId[vId]);
              }

              if(( onView && ! hasLayer ) || ( !onView && hasLayer ) ){
                setTimeout(function(){  
                $("input[value=" + vId + "]").trigger("click");
                  }, 200);
              }

              /* Set extent for the current view */
              if(onView){
                out = {
                  extent : vExt
                };
                Shiny.onInputChange("storyMapData",out);
              }
              
            }

          }
        }
    );
  }

updateStoryMaps = debounce(updateStoryMaps_orig,50);


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
    leafletvtId[id].setStyle(sty,layer);
  }else{
    mxSetStyle(id,vtStyle,layer,true);
  }
}




//
// Set time slider filter
//
function mxFilterDate_orig(id,date,lay){
  // copy style
  vtStyle = leafletvtId[id].vtStyle;
  // create function to apply
  var sty = function(feature) {

    var style = {};
    var selected = style.selected = {};
    var  type = feature.type,
    defaultColor = 'rgba(0,0,0,0)',
    dataCol = defaultColor,
    val = feature.properties[vtStyle.dataColum],
    dStart = parseInt(feature.properties.mx_date_start),
    dEnd = parseInt(feature.properties.mx_date_end),
    dFilter = parseInt(date),
    skip = false,
    hasDate = false ;
    if( typeof(dEnd) != "undefined" && typeof(dStart) != "undefined" ){
      hasDate = true;
      
      if( dFilter < dStart || dFilter > dEnd ){
        skip = true;
      }
    }


    if(skip){
       dataCol = defaultColor;
    }else{
      if( typeof(val) != 'undefined'){ 
        dataCol = hex2rgb(vtStyle.colorsPalette[val],vtStyle.opacity);
        if(typeof(dataCol) == 'undefined'){
          dataCol = defaultColor;
        }
      }
    }
    switch (type) {
      case 1: //'Point'
        style.color = dataCol;
        style.radius = vtStyle.size;
        selected.color = 'rgba(255,255,0,0.5)';
        selected.radius = 6;
        break;
      case 2: //'LineString'
        style.color = dataCol;
        style.size = vtStyle.size;
        selected.color = 'rgba(255,25,0,0.5)';
        selected.size = vtStyle.size;
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

  leafletvtId[id].setStyle(sty,lay);
}

var mxFilterDate = debounce(mxFilterDate_orig,50);

//
// Set time slider filter
//
function mxSetRange_orig(id,min,max,lay){
  // copy style
  vtStyle = leafletvtId[id].vtStyle;
  // create function to apply
  var sty = function(feature) {
    var style = {};
    var selected = style.selected = {};
    var  type = feature.type,
    defaultColor = 'rgba(0,0,0,0)',
    dataCol = defaultColor,
    val = feature.properties[vtStyle.dataColum],
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
        dataCol = hex2rgb(vtStyle.colorsPalette[val],vtStyle.opacity);
        if(typeof(dataCol) == 'undefined'){
          dataCol = defaultColor;
        }
      }
    }

    switch (type) {
      case 1: //'Point'
        style.color = dataCol;
        style.radius = vtStyle.size;
        selected.color = 'rgba(255,255,0,0.5)';
        selected.radius = 6;
        break;
      case 2: //'LineString'
        style.color = dataCol;
        style.size = vtStyle.size;
        selected.color = 'rgba(255,25,0,0.5)';
        selected.size = vtStyle.size;
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

  leafletvtId[id].setStyle(sty,lay);
}

var mxSetRange = debounce(mxSetRange_orig,50);

// 
// mx set style
//
function mxSetStyle_orig(id,vtStyle,lay,overwrite){

  // check if the provided style is the same as this already applied  
  if(!overwrite){
    if(vtStyle == leafletvtId[id].vtStyle){
      if(vtStyle.dataColumn == leafletvtId[id].vtStyle.dataColumn){
      }
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
    val = feature.properties[vtStyle.dataColum];
    if( typeof(val) != 'undefined'){ 
      // extract color by val
      col = vtStyle.colorsPalette[val];
      if(typeof(col) == "undefined"){
        var txt = "Error. No color found for " + val ;
        Shiny.onInputChange("leafletVtError",txt);
        console.log(txt);
      }
      dataCol = hex2rgb(col,vtStyle.opacity);
      if(typeof(dataCol) == 'undefined'){
        console.log("Error. dataCol undefined for "+val+"set default color");
        dataCol = defaultColor;
      }
    }

    switch (type) {
      case 1: //'Point'
        style.color = dataCol;
        style.radius = vtStyle.size;
        selected.color = 'rgba(255,255,0,0.5)';
        selected.radius = 6;
        break;
      case 2: //'LineString'
        style.color = dataCol;
        style.size = vtStyle.size;
        selected.color = 'rgba(255,25,0,0.5)';
        selected.size = vtStyle.size;
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

  leafletvtId[id].setStyle(sty,lay);
}

var mxSetStyle = debounce(mxSetStyle_orig,50);

// still used bx server/analysis
function defaultStyle(feature) {
  var style = {};
  var selected = style.selected = {};
  var type = feature.type;
  var dataCol = 'rgba(255,0,0,0.5)';
  var size = 5;

  switch (type) {
    case 1: //'Point'
      //style.color = 'rgba(49,79,79,1)';
      style.color = dataCol;
      style.radius = size;
      selected.color = 'rgba(255,255,0,0.5)';
      selected.radius = size+5;
      break;
    case 2: //'LineString'
      //style.color = 'rgba(161,217,155,0.8)';
      style.color = dataCol;
      style.size = size;
      selected.color = 'rgba(255,255,0,0.5)';
      selected.size = size;
      break;
    case 3: //'Polygon'
      style.color = dataCol;
      style.outline = {
        color: dataCol,
        size: 1
      };
      selected.color = 'rgba(255,255,0,0.5)';
      selected.outline = {
        color: 'rgba(255,0,0,1)',
        size: size
      };
      break;
  }
  return style;
}


