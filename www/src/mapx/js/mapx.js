



var storyMapLayer = {store:[]};

/* Object to hold ui and style state*/
var leafletvtId = {};




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
  },
  leftPanel : {
    id : "map-left-panel",
    modes :{
      fw:"map-left-panel-full-width",
      d:"map-left-panel-default",
      c:"map-left-panel-collapse"
    },
    mode : "map-left-panel-default",
    set:function(m){
      m = this.modes[m];
      el = document.getElementById(this.id);
      el.className = m;
    }
  }
};




// decode b64 and keep utf8 formating
// taken from http://stackoverflow.com/questions/30106476/using-javascripts-atob-to-decode-base64-doesnt-properly-decode-utf-8-strings
function b64_to_utf8( str ) {
  str = str.replace(/\s/g, '');    
  return decodeURIComponent(escape(window.atob( str )));
}
function utf8_to_b64( str ) {
  return window.btoa(unescape(encodeURIComponent( str )));
}

function toggleDropDown(id) {
  document.getElementById(id).classList.toggle("mx-dropdown-show");
}

// Generic read cookie function and send result to shiny
function readCookie()
{   
  var cookies = document.cookie.split("; ");
  var values = {};
  for (var i = 0; i < cookies.length; i++)
  {   
    var spcook =  cookies[i].split("=");
    values[spcook[0]]=spcook[1];
  }
  Shiny.onInputChange("readCookie", values);
}


function clearListCookies()
{
  var cookies = document.cookie.split(";");
  for (var i = 0; i < cookies.length; i++){   
    var spcook =  cookies[i].split("=");
    document.cookie = spcook[0] + "=;expires=Thu, 21 Sep 1979 00:00:01 UTC;";                                
  }
  window.location.reload();
}

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
              

              /*
                 out = {
                 view : storyMapLayer.store[0],
                 opacity : vOpa,
                 extent : vExt 
                 };

                 if(vId == "khimdtpsawmskngqhep"){
                 console.log( out );
                 }

                 Shiny.onInputChange("storyMapData",out);
                 */
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
    leafletvtId[id].setStyle(sty,layer+"_geom");
  }else{
    mxSetStyle(id,vtStyle,layer,true);
  }
}


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
 if(feature.properties.code=="5823"){
         debugger;
       }
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

  leafletvtId[id].setStyle(sty,lay+"_geom");
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

  leafletvtId[id].setStyle(sty,lay+"_geom");
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
        console.log("Error. No color found for "+val);
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

  leafletvtId[id].setStyle(sty,lay+"_geom");
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


// Update map panel elements interaction 
//
function updateMapElement(){
  //
  // Panel animation
  //
  var idViews = "#map-left-panel",
  idBtnViews = "#btnViewsCollapse",
  idInfo = "#info-box" ,
  idBtnInfo = "#btnInfoClick",
  idTitlePanel = "#titlePanelMode",
  idBtnStoryExpand = "#btnStoryEditorExpand",
  idMapLeftContent = ".map-left-content",
  idContainerStoryExpand = "#storyEditorContainer",

  // 
  //idSection = "#sectionMap",
  //idBody = $('body'),
  //idBtn = $("#btnStopMapScroll");
  //idBtn = $(".btn-stop-map-scroll");

  // set default state
  toggleScrollMap = true,
  toggleCollapseViews = true,
  toggleCollapseInfoClick = true,
  toggleStoryEditorExpand = true;
  //
  //  map panel lock button 
  //
/*  idBtn.click(function(){ */
    //if(toggleScrollMap){
      //idBtn.html("<i class='fa fa-lock'>");
      //$('html, body').stop().animate({
        //scrollTop: $(idSection).offset().top - $(".navbar-fixed-top").height() 
      //}, 100, 'easeOutQuad');
      //idBody.addClass('noscroll');
    //}else{
      //idBtn.html("<i class='fa fa-unlock'>");
      //idBody.removeClass('noscroll');
    //}
    //toggleScrollMap = !toggleScrollMap ;
  //});

  // Story map editor expand

/*  $(idBtnStoryExpand).click(function(){*/
    //if(toggleStoryEditorExpand){ 
      //$(idContainerStoryExpand).addClass("editor-full-width");
      //$(idContainerStoryExpand).draggable({ 
        ////handle: idContainerStoryExpand,
        //cancel: "#txtStoryMap",
        //containment: $(idSection),
        //cursor: "crosshair"
      //});
      //$(idBtnStoryExpand).html("<i class='fa fa-compress'></i>");
      //$('html, body').stop().animate({
        //scrollTop: $(idSection).offset().top - $(".navbar-fixed-top").height() 
      //}, 100, 'easeOutQuad');
      //idBody.addClass('noscroll');
    //}else{
      //$(idContainerStoryExpand).removeClass("editor-full-width");
      //$(idBtnStoryExpand).html("<i class='fa fa-expand'></i>");
      //if(toggleScrollMap){
        //idBody.removeClass('noscroll');
      //}
    //}
    //toggleStoryEditorExpand = !toggleStoryEditorExpand;

  /*});*/


  // add a click function to btn collapse views 
  $(idBtnViews).click(function(){

     var  mapLeftWidth = $(idViews).width()*2;

    if(toggleCollapseViews){
      $(idViews).animate({left: - mapLeftWidth },500);
      //$(idInfo).animate({left:"70px"},500);
      $(idBtnViews).html("<i class='fa fa-angle-double-right'>");
      $(idTitlePanel).css({opacity:"0"});
      $(idMapLeftContent).css({opacity:"0"});
    }else{ 
      $(idViews).animate({left:"0px"},500);
      //$(idInfo).animate({left:"600px"},500);
      $(idBtnViews).html("<i class='fa fa-angle-double-left'>");
      $(idTitlePanel).css({opacity:"1"});
      $(idMapLeftContent).css({opacity:"1"});
    }
    toggleCollapseViews = !toggleCollapseViews;
  });

  // add a click function to btn info panel
  $(idBtnInfo).click(function(){
    mxConfig.mapInfoBox.toggle();
  });

  /* add scroll listener to story map */

  var storyCont = $("#mapLeftScroll");
  storyCont.on("scroll",updateStoryMaps);

}


