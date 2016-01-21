<?php
include("mcr_pshare.php");
$ml=new McrLog($_GET['file']);
echo $ml->getJson();
?>
