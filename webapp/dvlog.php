<!DOCTYPE html>
<html lang="en-US">
  <head>
    <meta charset="utf-8"/>
    <link rel="stylesheet" type="text/css" href="ciax-xml.css"/>
    <script type="text/javascript" src="jquery-3.0.0.min.js"></script>
    <script type="text/javascript">
      var par = <?php echo json_encode($_GET); ?>;
      $.getJSON('sqlog.php', par, function(obj) {
        $(".title").append('<span class="head">' + par.site + ':' + par.vid + '</span>');
        obj[0].data.forEach(function(pair) {
          var date = new Date(pair[0] - 0);
          var time = date.toLocaleTimeString('en-US', {hour12: false})
          $("tbody").append('<tr><td><span class="label">' + time + '</span></td><td class="item"><var>' + pair[1] + '</var></td></tr>');
        });
      });
    </script>
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
