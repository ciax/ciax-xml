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
$port=(int)getarg('port');
$cmd=getarg('cmd');
$soc=socket_create(AF_INET,SOCK_DGRAM,SOL_UDP);
$buf='["'.$cmd.'"]';
$len=strlen($buf);
socket_sendto($soc,$buf,$len,0,"127.0.0.1",$port);
$from="";
$port=0;
socket_recvfrom($soc,$buf,1024,0,$from,$port);
print($buf);
?>
