
/* 

   bindings 

*/

Shiny.addCustomMessageHandler("updateChart",
    function(m) {
      var data = {
        labels: m.labels,
        datasets: [ m.dataMain , m.dataComp ]
      };

      var ctx = document.getElementById(m.id).getContext('2d'); 
      //var mxChart = new Chart(ctx).Radar(data);
      var mxChart = new Chart(ctx, {
            type: 'radar',
            data: data
      });
      var chartLegend = mxChart.generateLegend();
      $('#'+m.idLegend).html(function(){return chartLegend;});


    }
    );

