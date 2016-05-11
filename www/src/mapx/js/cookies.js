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
  return values ;
}

// cookie input
var shinyCookieInputBinding = new Shiny.InputBinding();
$.extend(shinyCookieInputBinding, {
  find: function(scope) {
    return  $(scope).find(".shinyCookies");
  },
  getValue: function(el) {
    return readCookie();
  } 
});
Shiny.inputBindings.register(shinyCookieInputBinding);


// shiny binding to set cookie.
Shiny.addCustomMessageHandler("mxSetCookie",
    function(e) {

      if( e.expiresInSec.length === 0 ){
        exp = undefined ;
      }else{
        exp = e.expiresInSec;
      }


      if(e.deleteAll){
        exp = '01/01/2012';
        e.cookie = readCookie();
      }



      for( var c  in e.cookie){
        Cookies.set(c,e.cookie[c],{
          'path':e.path,
          'domain':e.domain,
          'expires':exp}
          );
      }

      if(e.reload){
        window.location.reload();
      }
    }
);
