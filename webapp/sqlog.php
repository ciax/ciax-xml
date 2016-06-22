<?php
#Required packages: php5-sqlite
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
$time=getarg('time');
$vid=getarg('vid');
$tol=3600000;

$fname='/var/www/html/log/sqlog_'.$site.'.sq3';
$pdo=new PDO('sqlite:'.$fname);
if($pdo){
    $str = 'SELECT * FROM status_1 WHERE time BETWEEN '.($time-$tol).' and '.($time+$tol);
    $st=$pdo->query($str);
    if ($st){
        $all=$st->fetchAll(PDO::FETCH_NUM);
        if ($all) echo(json_encode($all));
    }
}
?>
