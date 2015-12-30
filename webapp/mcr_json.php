<?php
include("libmcr.php");
$ml=new McrLog($_GET['file']);
echo $ml->getJson();
?>
