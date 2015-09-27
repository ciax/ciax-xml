<?php
function getarg($key){
  $res=$_POST[$key] ;
  $res=($res) ? $res : $_GET[$key];
  return $res;
}
$site=getarg('site');
$cmd=getarg('cmd');
print(`./dvctl.sh $site $cmd 2>&1`);
?>
