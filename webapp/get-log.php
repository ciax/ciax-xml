<?php
function getarg($key){
  global $args;
  $res=(isset($_POST[$key])) ? $_POST[$key] :
    (
      (isset($_GET[$key])) ? $_GET[$key] :
        (
          (isset($args[$key])) ? $args[$key] : null
        )
    );
  return $res;
}
$args=array();
foreach($argv as &$e){
  $ary=split("=",$e);
  if(count($ary)>1){
    $args[$ary[0]]=$ary[1];
  }
}
$site=getarg('site');
$vid=getarg('vid');
$fname='/var/www/html/log/status_'.$site.'_2016.log';
$handle = fopen($fname,"r");
$first = true;
if($handle){
    $json = array();
    while(($line = fgets($handle, 4096)) !== false){
        $buf=json_decode($line, true);
        $json[] = array($buf['time'], $buf['data'][$vid]);
    }
    print(json_encode($json));
}
?>
