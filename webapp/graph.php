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
      var par = <?php echo json_encode($_GET); ?>;
      $(get_graph);
    </script>
   </head>
  <body>
    <div id="placeholder" style="width:600px;height:300px;"></div>
  </body>
</html>
