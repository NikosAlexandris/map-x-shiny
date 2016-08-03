var webfontsGenerator = require('webfonts-generator'),
    fs = require('fs'),
    config = {};
config.svgFiles = [];

config.svgPath = "src/mx-font-icon/";
config.destPath = "fonts/mapx/";
config.outName =  "mx-font-icon";
config.classBase = "mx";
config.classPrefix = "mx-";
config.cssTemplate = "fonts/mapx/mx-font-icon-template.hbs";

fs.readdir(config.svgPath, function(err, files)
    {
      if (err) return;
      files.forEach(function(f)
          {
            var fl = f.length;
            var fe = fl-4;
            var isSvg = f.substr(fe,fl) === ".svg";

            if( isSvg )
            {
              config.svgFiles.push(config.svgPath+f);
            }
          }
          );

      if(config.svgFiles.length > 0)
      {
        webfontsGenerator(
            {
              files: config.svgFiles,
              dest: config.destPath,
              fontName: config.outName,
              cssTemplate:config.cssTemplate,
              templateOptions : {
                classPrefix : config.classPrefix,
                baseClass : config.classBase
              }
            }, function(error)
            {
              if (error) console.log('Fail!', error);
              else console.log('Done!');
            }
            );

        console.log(config.svgFiles);
      }
    }
);


