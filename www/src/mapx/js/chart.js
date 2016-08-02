
/* 

   bindings 

*/


mxCharts = {};


Shiny.addCustomMessageHandler("updateChart",
    function(m) {
      var data = {
        labels: m.labels,
        datasets: [ m.dataMain , m.dataComp ]
      };



      if(mxCharts[m.id]){
        mxCharts[m.id].destroy();
      }

        var ctx = document.getElementById(m.id).getContext('2d'); 
        //var mxChart = new Chart(ctx).Radar(data);
        var mxChart = new Chart(ctx, {
          type: 'radar',
          data: data
        });

        mxCharts[m.id] = mxChart;

      var chartLegend = mxCharts[m.id].generateLegend();
      $('#'+m.idLegend).html(
          function(){
            return chartLegend;
          }
          );


    }
);

