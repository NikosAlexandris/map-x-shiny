
Shiny.addCustomMessageHandler("jsonToObj",
    function(jsonRaw) {
      window[jsonRaw.name] = JSON.parse(jsonRaw.json);
    }
    );

Shiny.addCustomMessageHandler("jsDebugMsg",
    function(m) {
      console.log(m.msg);
    }
);

Shiny.addCustomMessageHandler("mxSetButonState",
    function(r) {

      if(r.disable === true){
        $("#"+r.id)
          .addClass("btn-danger")
          .removeClass("btn-default")
          .removeClass("btn-warning")
          .attr("disabled",true); 
      }else if(r.warming === true){ 
        $("#"+r.id)
          .addClass("btn-warning")
          .removeClass("btn-default")
          .removeClass("btn-danger")
          .attr("disabled",false); 
      }else{
        $("#"+r.id)
          .addClass("btn-default")
          .removeClass("btn-danger")
          .removeClass("btn-warning")
          .attr("disabled",false); 
      }
    }
    );

Shiny.addCustomMessageHandler("mxUiEnable",
    function(r) {
      if(r.enable === true){
        $(r.element).removeClass(r.classToRemove);
      }else{ 
        $(r.element).addClass(r.classToRemove);
      }
    }
    );


Shiny.addCustomMessageHandler("mxRemoveEl",
    function(e) {
    $(e.element).remove();
    }
);

Shiny.addCustomMessageHandler("mxUpdateValue",
    function(e) {
      el = document.getElementById( e.id );
      el.value = e.val;
    }
    );

Shiny.addCustomMessageHandler("setStyle",
    function(e) {
      mxSetStyle(e.group,e.style,e.layer,false);
    }
);

Shiny.addCustomMessageHandler("addCss",
    function(fileName) {
      $("head").append("<link>");
      var css = $("head").children(":last");
      css.attr({
        rel:  "stylesheet",
        type: "text/css",
        href: fileName
      });
    }
    );


Shiny.addCustomMessageHandler("updateText",
    function(m) {
      el = document.getElementById(m.id);
      if( typeof el != "undefined" && el !== null ){
        el.innerHTML=b64_to_utf8(m.txt.toString());
        if(m.addId){
          setUniqueItemsId();
        }
      }
    }
    );



Shiny.addCustomMessageHandler("mapUiUpdate",
    function(message){
      updateMapElement();
    }
    );


