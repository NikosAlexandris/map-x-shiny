var fs = require('fs');
var CleanCSS = require('clean-css');
var outFile = "dist/assets.css";

var inFile =  [ 
    "src/font-awesome-4.4.0/css/font-awesome.min.css", 
    "src/theme/grayscale/bootstrap.min.css",
    "src/handsontable/handsontable.full.min.css",
    "src/ionRangeSlider/css/ion.rangeSlider.css",
    "src/ionRangeSlider/css/ion.rangeSlider.skinNice.css",
    "src/bootstrapTour/css/bootstrap-tour.min.css",
    "src/mapx/css/mapx.css",
    "src/mapx/css/infobox.css",
    "src/mapx/css/accordion.css"
    ];



var result = new CleanCSS({target:outFile,relativeTo:'dist'}).minify(inFile);


fs.writeFile(outFile, result.styles, function(err) {
  if(err) {
    return console.log(err);
  }
  console.log("Writing " + outFile + " done !\n" + "Input files:",inFile);
}); 


