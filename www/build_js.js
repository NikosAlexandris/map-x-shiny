var fs = require("fs");
var UglifyJS = require("uglify-js");
var outFile = "dist/assets.js";
var inFile = [
  "src/cookies/cookies.min.js",
  "src/chartjs/Chart.min.js",
  "src/handsontable/handsontable.full.min.js",
  "src/handsontable/shinyskyHandsonTable.js",
  "src/ionRangeSlider/js/ion-rangeSlider/ion.rangeSlider.min.js",
  "src/bootstrap/js/bootstrap.min.js",
  "src/bootstrapTour/js/bootstrap-tour.min.js",
  "src/mapx/js//mapxChartJsConf.js",
  "src/mapx/js/pwd.js",
  "src/mapx/js/md5.js",
  "src/mapx/js/lang_ui.js",
  "src/mapx/js/base64.js",
  "src/mapx/js/lang_tours.js",
  "src/jqueryUI/custom/jquery-ui.min.js",
  "src/mapx/js/mapx.js"
];


var result = UglifyJS.minify(inFile,{
  mangle : true,
  compress : true
});

fs.writeFile(outFile, result.code, function(err) {
  if(err) {
    return console.log(err);
  }
  console.log("Writing " + outFile + " done !\n" + "Input files:\n",inFile);
}); 


