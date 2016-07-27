

var leafletvtId = {};
var leafletvtLoaded = {};

var subset = function(object, keys) {
  var tmp = {};
  keys.forEach(function(key) { tmp[key] = object[key]; });
  return tmp;
};

LeafletWidget.methods.setZoom = function(zoom,options){
  this.setView(this.getCenter(), zoom, options);
};

hex2rgb = function(hex, opacity) {
  var h=hex.replace("#", "");
  h =  h.match(new RegExp("(.{"+h.length/3+"})", "g"));

  for(var i=0; i<h.length; i++)
    h[i] = parseInt(h[i].length==1? h[i]+h[i]:h[i], 16);

  if (typeof opacity != "undefined")  h.push(opacity);

  return "rgba("+h.join(",")+")" ;
};

function objToList(obj,hide){
  if(typeof(hide) != "undefined"){  
    for(var h in hide){
      delete obj[hide[h]];
    }
  }
  var html = "<ul class='list-group'>";
  var img = "";
  for(var key in obj){
    val = obj[key];

    if(typeof(val)=="string" && val.search("\.jpg$") > 0){ 
      /* if it's an image, set as header */
      img = "<img style='width: 100%;' src='" + val + "' alt='" + val + "'>";
    }else{

      if(typeof(val)=="string" && val.substring(0,7)=="http://"){
        /* if it's a link : redirect */
        val="<a href='"+val+"' target='_blank' download=''>"+key+" link</a>";
      }

      html += 
        "<li class='list-group-item' >"+
        "<span class='badge badge-white'>"+ val +"</span>"+
        key +"</li>";

    }

  }
  html += "</ul>";
  html = img + html ;
  return html;
}

function objToTable(obj){
  classTable="table"; // boostrap table...
  var html = "<table class="+classTable+"><tr>";
  var key = "";
  for(key in obj){
    if(key !== "gid"){
      html += "<th>"+key+"</th>";
    }
  }
  html += "</tr><tr>";
  for(key in obj){
    if(key !== "gid"){
      val = obj[key];
      if(typeof(val)=="string" && val.substring(0,7)=="http://"){
        val="<a href='"+val+"'>"+key+" link</a>";
      }
      html += "<td>"+val+"</td>";
    }
  }
  html += "</tr></table>";
  return html;
}


// load array content as object key and value..
function toObject(arr) {
  var rv = {};
  for (var i = 0; i < arr.length; ++i)
    rv[arr[i]] = arr[i];
  return rv;
}

LeafletWidget.methods.setVectorTilesVisibility = function(group,visible) {
  var legId = group + "_legends";
  var  g = leafletvtId[group];
  var l = {};
  if(g){
    if(visible){
      l = leafletvtLegends[group];
      if(l){
        this.addLayer(l);
      }
      this.addLayer(g);
    }else{
      this.removeLayer(g);
      l = this.getLayer(legId);
      if(l){
        leafletvtLegends[group] = l;
        this.removeLayer(l);
      }
    }
  }
};


LeafletWidget.methods.hideGroup = function(group) {
  var self = this;
  $.each(asArray(group), function(i, g) {
    var layer = self.layerManager.getLayerGroup(g, true);
    if (layer) {
      self.removeLayer(layer);
    }
  });
};


var randomHsl = function(opacity) {
  var col = "hsla(" + (Math.random() * 360) + ", 100%, 50%, "+ opacity +")";
  return col;
};



// mapbox gl handler


var glMap = {};

LeafletWidget.methods.glInit = function( idGl, idMap, style, token ){


  var glLayer = L.mapboxGL({
    container: idMap,
    style: style,
    accessToken: token
  }) ;
  // save as leaflet layer
  this.addLayer(glLayer);
  //this.layerManager.addLayer( glLayer, "tile", idGl ); 
  // we want to have quick access to gl map
  gl = glLayer._glMap ;
  gl.on("load",function(){ 
    Shiny.onInputChange("glLoaded",idGl);
  });
  glMap[ idGl ] = gl ;


}; 


LeafletWidget.methods.glAddSource = function( idGl , idSource, style ){
  gl = glMap[ idGl ];

  gl.addSource( idSource , style );
  Shiny.onInputChange("glLoadedSource", idSource );
};

LeafletWidget.methods.glRemoveSource = function( idGl, idSource ){
  gl = glMap[ idGl ];
  gl.removeSource( idSource );
};


LeafletWidget.methods.glAddLayer  = function( idGl, idBelowTo, style ){
  gl = glMap[ idGl ];
  if(idBelowTo){
    gl.addLayer( style, idBelowTo );
  }else{
    gl.addLayer( style );
  }
  var l = [];
  for(var key in gl.style._layers){l.push(key);}
  
  Shiny.onInputChange("glLoadedLayers",l);
};

LeafletWidget.methods.glRemoveLayer  = function( idGl, idLayer ){

  gl = glMap[ idGl ];

  if(gl.getLayer(idLayer) !== undefined ){
      gl.removeLayer( idLayer );
  }
};

LeafletWidget.methods.glSetPaintProperty = function( idGl, idLayer, name , value ){
  gl = glMap[ idGl ];
  gl.setPaintProperty(idLayer,name,value);
};

LeafletWidget.methods.glSetFilter = function( idGl, idLayer, filter ){
  gl = glMap[ idGl ];
  gl.setFilter(idLayer,filter);
};




LeafletWidget.methods.addVectorTiles = function(urlTemplate,vectLayer,idColumn,layerId,group,options) {


  if(typeof group === "undefined"){
    group="default" ;
  }

  if(layerId === null){
    layerId=group ;
  }

  if(typeof options.debug == "undefined"){
    debug=false;
  }else{
    debug=options.debug;
  }
  // NOTE: to be set in debug mode.
  //  var start = new Date().getTime();

  // if(typeof leafletvtId[group] == "undefined"){

  //var zIndex = options.zIndex;
  var zIndex = 10;

  var config = {
    url:urlTemplate,
    mutexToggle: true,
    debug: debug,
    clickableLayers: [vectLayer],
    getIDForLayerFeature: function(feature) {
      return feature.properties[idColumn];
    },
    onClick: function(evt) {
      var attrMode =  document
        .getElementById("checkAttributes")
        .checked;

      var feature = evt.feature;
      var coord = evt.latlng;
      var showTable = true;
      if(attrMode){
        //Shiny.onInputChange("leafletvtClickCoord",coord);
        if(feature !== null && typeof feature !== undefined){
          featureProp = feature.properties;

          var popup = L.popup({
            minWidth:300,
            minHeight:200,
            maxHeight:400,
            maxWidth:400,
            closeOnClick:true}) 
            .setLatLng(evt.latlng)
            .setContent(objToList(featureProp,['gid','mx_date_start','mx_date_end']))
            .openOn(feature.map);
        }
      }else{ 
        if(feature !== null && typeof feature !== undefined){
          feature.deselect();
        }
      }
    },
    filter: function(feature, context) {
      if (feature.layer.name === vectLayer) {
        return true;
      }
      return false;
    },
    onTilesLoaded: function() {
      var feedBack  = options.onLoadFeedback;
      if( typeof feedBack != "undefined" ){
        if( feedBack != "never" ){
          if( typeof leafletvtLoaded[layerId] == "undefined" ){
            if( feedBack == "once" ){      
              leafletvtLoaded[layerId] = new Date().getTime();
            }
            var leafletvtData = {
              "lay":vectLayer,
              "grp":group,
              "id":layerId
            };
            Shiny.onInputChange("leafletvtIsLoaded",leafletvtData);
          }
        }
      }
    },
    // DEFAULT STYLE. Will be modified after.
    style: function (feature) {
      var s = {};
      //feature.properties.group == "active"
      s.color = "rgba(0,0,0,0)";
      return s ;

    }
  };


  var vecTile = new L.TileLayer.MVTSource(config);


  this.layerManager.addLayer(vecTile, "tile", layerId, group); 

  //TODO: avoid this object (used in mxSetStyle) and use the layer manager instead.
  leafletvtId[group] = vecTile;




  // get available id keys
  var leafletvtViews = toObject(Object.keys(leafletvtId));
  // update input$leafletvtViews 
  Shiny.onInputChange("leafletvtViews",leafletvtViews);


};



