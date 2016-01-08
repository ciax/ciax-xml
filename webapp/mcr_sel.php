<HTML>
<HEAD>
<TITLE>MCR LOG SELECT</TITLE>
<link rel="stylesheet" type="text/css" href="mcr_style.css">
</HEAD>
<BODY>
<H2>SELECT DATE</H2>
<?php
include("mcr_pshare.php");
$ld=new LogDate;
foreach($ld->getList() as $val){
    echo '<li><a href="mcr_log.php?file=';
    echo  htmlentities($val[1]);
    echo '" target=FRM2>';
    echo $val[0];
    echo "</a>\n";
}
?>
</BODY>
</HTML>
