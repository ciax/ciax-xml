<!DOCTYPE html>
<html lang="en-US">
  <head>
    <meta charset="utf-8"/>
    <link rel="stylesheet" type="text/css" href="ciax-xml.css"/>
    <script type="text/javascript" src="jquery-3.0.0.min.js"></script>
    <script type="text/javascript">
      var par = <?php echo json_encode($_GET); ?>;
    </script>
    <script type="text/javascript" src="dvlog.js"></script>
  </head>
  <body>
    <div class="outline">
      <div class="title"></div>
      <table>
        <tbody>
          <tr><th>Time</th><th>Value</th></tr>
        </tbody>
      </table>
    </div>
  </body>
</html>
