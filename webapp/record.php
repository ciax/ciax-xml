<html>
<head>
<title>CIAX-XML(Record)</title>
<link rel="stylesheet" type="text/css" href="ciax-xml.css"/>
     <script type="text/javascript" src="http://ajax.googleapis.com/ajax/libs/jquery/1.11.0/jquery.min.js"></script>
     <script type="text/javascript" src="record.js"></script>
     <script type="text/javascript">
<?php
     $tag='latest';
if(isset($_GET['id'])){ $tag=$_GET['id'];};
echo 'tag="' . $tag . '";';
?>
$(document).ready(static);
</script>
<body>
<div class="outline">
    <div class="title">Macro Log</div>
    <div id="output"></div>
    </div>
    </body>
    </html>