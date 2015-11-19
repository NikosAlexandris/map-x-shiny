jQuery(function($) {
  // Password Input
  var passwordInputBinding = new Shiny.InputBinding();
  $.extend(passwordInputBinding, {
    find: function(scope) {
      return $(scope).find('input[type="password"]');
    },
    getId: function(el) {
      return Shiny.InputBinding.prototype.getId.call(this, el) || el.name;
    },
    getValue: function(el) {
      return md5(el.value);
    },
    setValue: function(el, value) {
      el.value = value;
    },
    subscribe: function(el, callback) {
      $(el).on('keyup.passwordInputBinding input.passwordInputBinding', function(event) {
        callback(true);
      });
      $(el).on('change.passwordInputBinding', function(event) {
        callback(false);
      });
    },
    unsubscribe: function(el) {
      $(el).off('.passwordInputBinding');
    },
    getRatePolicy: function() {
      return {
        policy: 'debounce',
        delay: 250
      };
    }
  });
  Shiny.inputBindings.register(passwordInputBinding, 'shiny.passwordInput');
});


jQuery(function($) {
  // User name input
  var usernameInputBinding = new Shiny.InputBinding();
  $.extend(usernameInputBinding, {
    find: function(scope) {
      return $(scope).find('input[class="mxLoginInput usernameInput"]');
    },
    getId: function(el) {
      return Shiny.InputBinding.prototype.getId.call(this, el) || el.name;
    },
    getValue: function(el) {
      return md5(el.value);
    },
    setValue: function(el, value) {
      el.value = value;
    },
    subscribe: function(el, callback) {
      $(el).on('keyup.usernameInputBinding input.usernameInputBinding', function(event) {
        callback(true);
      });
      $(el).on('change.usernameInputBinding', function(event) {
        callback(false);
      });
    },
    unsubscribe: function(el) {
      $(el).off('.usernameInputBinding');
    },
    getRatePolicy: function() {
      return {
        policy: 'debounce',
        delay: 250
      };
    }
  });
  Shiny.inputBindings.register(usernameInputBinding, 'shiny.usernameInput');
});






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

// Delete all cookie value NOTE: cookie path rewriting
// http://stackoverflow.com/questions/595228/how-can-i-delete-all-cookies-with-javascript#answer-11095647
function clearListCookies()
{   
  var cookies = document.cookie.split(";");
  for (var i = 0; i < cookies.length; i++)
  {   
    var spcook =  cookies[i].split("=");
    deleteCookie(spcook[0]);
  }
  function deleteCookie(cookiename)
  {
    var d = new Date();
    d.setDate(d.getDate() - 1);
    var expires = ";expires="+d;
    var name=cookiename;
    var value="";
    document.cookie = name + "=" + value + expires + "; path=/";                    
  }
  //readCookie();
  document.location.reload(true)
}


$( document ).ready(function( $ ) {
// Eval cookie functions (set, delete)
Shiny.addCustomMessageHandler("mxSetCookie",
    function(message) {
      eval(message.code);
      readCookie();
    }
    );
});






