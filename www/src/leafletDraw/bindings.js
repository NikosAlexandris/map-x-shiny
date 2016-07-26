




LeafletWidget.methods.setDraw = function(options,display){



 if( ! this.draw ){
      this.draw = {};
    }




  if( !display ) {

    this.draw.control.removeFrom( this ) ;
    this.removeLayer( this.draw.items ) ;
    delete this.draw.control ;

  }else{

   
    if( ! this.draw.items ){
      this.draw.items = new L.FeatureGroup();
      this.addLayer( this.draw.items );
    }else{
    
      this.addLayer( this.draw.items );
    }

    // note : circle disable as retrieving geojson is not yet possible
    // see #390
    options.edit = {
      featureGroup : this.draw.items,
    };

    options.draw = {
      circle:false
    };

    this.draw.control = new L.Control.Draw( options );
     
    this.draw.control.addTo( this );
    //
    // Events
    //
    this.on('draw:created', function( e ) {
      // e.layerType string (polyline/polygon/rectangle/circle/marker)
      // e.layer Polyline/Polygon/Rectangle/Circle/Marker
      // var type = e.layerType,
      layer = e.layer;
      this.draw.items.addLayer( layer ) ;
      Shiny.onInputChange("leafletDrawGeoJson",this.draw.items.toGeoJSON());
    });
    this.on('draw:edited', function ( e ) {
      //e.layers LayerGroup List of all layers just edited on the this.
      var layers = e.layers;
      Shiny.onInputChange("leafletDrawGeoJson",this.draw.items.toGeoJSON());
    });
    this.on('draw:drawstart', function ( e ) {
      //e.layerType String The type of layer this is. One of: polyline...
      Shiny.onInputChange( "leafletDrawStart" , (new Date()).getTime() );
    });
    this.on('draw:drawstop', function ( e ) {
      //e.layerType String The type of layer this is. One of: polyline...
      var layerType = e.layerType;
      Shiny.onInputChange( "leafletDrawStop", (new Date()).getTime() );
    });
    this.on('draw:editstart', function ( e ) {
      //e.handler String The type of edit this is. One of: edit
      Shiny.onInputChange("leafletDrawEditStart", (new Date()).getTime() );
    });
    this.on('draw:editstop', function ( e ) {
      //e.handler String The type of edit this is. One of: edit
      Shiny.onInputChange("leafletDrawEditStop" , (new Date()).getTime() );
    });

    this.on('draw:deletestart', function ( e ) {
      //e.handler String The type of edit this is. One of: remove
        Shiny.onInputChange( "leafletDrawDeleteStart" , (new Date()).getTime() );
    });
    this.on('draw:deletestop', function (e) {
      //e.handler String The type of edit this is. One of: remove
      Shiny.onInputChange( "leafletDrawDeleteStop" , (new Date()).getTime() );
    });
  }
};


LeafletWidget.methods.removeDraw = function( ){
  this.draw.control.removeFrom( this ) ;
  delete this.draw.control ;
  this.removeLayer( this.draw.items ) ;
};

//
//LeafletWidget.methods.deleteDraw = function( ){
//  this.removeLayer(tmpLayer);
//};
//







