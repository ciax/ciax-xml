<html>
<head>
<title>MCR LOG</title>
<link rel="stylesheet" type="text/css" href="mcr_style.css">
<?php
include("mcr_pshare.php");
$ld=new LogDate;
$logfile=$ld->getFname();
$ml=new McrLog($logfile);
if($ld->isToday()){
  echo '<script type="text/javascript" src="prototype.js"></script>'."\n";
  echo '<script type="text/javascript" src="mcr_jshare.js"></script>'."\n";
  echo '</head>'."\n";
  echo '<body'.' onLoad=init("'.$logfile.'","'.$ml->getFp().'")>'."\n";
}else{
  echo '</head>'."\n";
  echo '<body>'."\n";
}
?>
<h1 class="MCRLOG">MCR LOG</h1>
<table class="MCRLOG">
<colgroup span=1 class="DATE" />
<tbody id="mcr">
<?= $ml->getTbody() ?>
</tbody>
</table>
</body>
</html>
