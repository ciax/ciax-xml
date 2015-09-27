<?php
$site=$_POST['site']||$_GET['site'];
$cmd=$_POST['cmd']||GET['cmd'];
print(`./dvctl.sh $site $cmd 2>&1`);
?>
