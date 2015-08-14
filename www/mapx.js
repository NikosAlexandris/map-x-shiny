
Shiny.addCustomMessageHandler("jsCode",
    function(message) {
      console.log(message);
      eval(message.code);
    }
    );

function $$(selector, context) {
    context = context || document;
      var elements = context.querySelectorAll(selector);
        return Array.prototype.slice.call(elements);
} 

$$('span.donut').forEach(function(pie) {
console.log(pie);
pie.pety("donut");
}
);
