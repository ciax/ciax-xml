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
// default host is localhost
//$host=getarg('host');
if(!$host){ $host="127.0.0.1"; }
$port=(int)getarg('port');
// cmd format "cmd:par1:par2.."
$cmds=split(":",getarg('cmd'));
$soc=socket_create(AF_INET,SOCK_DGRAM,SOL_UDP);
$buf=json_encode($cmds);
$len=strlen($buf);
socket_sendto($soc,$buf,$len,0,$host,$port);
$from="";
$port=0;
socket_recvfrom($soc,$buf,1024,0,$from,$port);
print($buf);
?>
