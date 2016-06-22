<!DOCTYPE html>
<html lang="en-US">
  <head>
    <meta charset="utf-8"/>
    <script type="text/javascript" src="jquery-3.0.0.min.js"></script>
    <script type="text/javascript" src="jquery.flot.min.js"></script>
    <script type="text/javascript" src="jquery.flot.time.min.js"></script>
    <script type="text/javascript" src="jquery.flot.navigate.min.js"></script>
    <script type="text/javascript" src="graph.js"></script>
    <script type="text/javascript">
      function get_graph() {
          var time = <?php echo '"'.$_GET['time'].'"'; ?>;
          var url = <?php echo '"sqlog.php?site='.$_GET['site'].'&vid='.$_GET['vid'].'&time="'; ?> + time;
          $.getJSON(url , function(data) {
              var options = {
                series: {
                    lines: { show: true },
                    points:{ show: true, radius: 3 }
                },
                grid: {
                    markings: [ {
                            color: '#ff0000',
                            lineWidth: 3,
                            xaxis: { from: time, to: time }
                          } ]
                },
                xaxis: { mode: 'time', timezone: 'browser' },
                zoom: { interactive: true },
                pan: { interactive: true }
              };
              $.plot($('#placeholder'), [data], options);
          });
      }
      $(document).ready(get_graph);
    </script>
   </head>
  <body>
    <div id="placeholder" style="width:600px;height:300px;"></div>
  </body>
</html>
