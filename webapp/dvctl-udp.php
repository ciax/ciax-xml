<?php
function getarg($key){
  $res=$_POST[$key] ;
  $res=($res) ? $res : $_GET[$key];
  return $res;
}
$port=(int)getarg('port');
$cmd=getarg('cmd');
$soc=socket_create(AF_INET,SOCK_DGRAM,SOL_UDP);
$msg='["'+$cmd+'"]';
$len=strlen($msg);
socket_sendto($soc,$msg,$len,0,"127.0.0.1",$port);
$from=""
socket_recvfrom($soc,$buf,12,0,$from,$port)
print($buf);
print("OK");
?>
