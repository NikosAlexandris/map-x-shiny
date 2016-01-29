testStyle = function (feature) {
      var style = {};
      var selected = style.selected = {};
      var type = feature.type;
      var dataCol = randomHsl(1);
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
            color: 'rgba(0,0,0,0)',
            size: 100
          };
          selected.color = 'rgba(255,0,0,0.3)';
          selected.outline = {
            color: 'rgba(255,0,0,1)',
            size: size
          };
          break;
      };
return style;

};

setInterval(function(){leafletvtGroup.G1.setStyle(testStyle,"afg__displaced_from__2012__a_geom");},100);

