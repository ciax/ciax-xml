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
$vid=getarg('vid');

$fname='/var/www/html/log/sqlog_'.$site.'.sq3';
echo $fname;
$pdo=new PDO('sqlite:'.$fname);
if($pdo){
    $st=$pdo->prepare('SELECT * FROM status_1');
    $st->execute();
    $all=$st->fetchAll(PDO::FETCH_NUM);
    echo(json_encode($all));
}
?>
