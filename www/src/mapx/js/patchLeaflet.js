

LeafletWidget.methods.setZoomOptions = function(buttonOptions,removeButton){
  z = document.querySelector(".leaflet-control-zoom");
  if( typeof buttonOptions !== "undefined" ){
    if( typeof(z) !== "undefined" && z !== null){
      z.parentNode.removeChild(z);
    }
    if(!removeButton){
      zC = L.control.zoom(buttonOptions);
      zC.addTo(this);
    }
  }
};
