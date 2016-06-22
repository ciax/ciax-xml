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
function get_tbl($pdo){
    $tbl = 'SELECT tbl_name FROM sqlite_master WHERE type="table"';
    $st=$pdo->query($tbl);
    if ($st){
        $all=$st->fetchAll(PDO::FETCH_COLUMN);
        if ($all) return(join(',',$all));
    }
}

$site=getarg('site');
$time=getarg('time');
$vid=getarg('vid');
$tol=3600000;

$fname='/var/www/html/log/sqlog_'.$site.'.sq3';
$pdo=new PDO('sqlite:'.$fname);
if($pdo){
    $tbls = get_tbl($pdo);
    if($tbls){
        $qry = 'SELECT time,'.$vid.' FROM '.$tbls.' WHERE time BETWEEN '.($time-$tol).' and '.($time+$tol);
        $st=$pdo->query($qry);
        if ($st){
            $all=$st->fetchAll(PDO::FETCH_NUM);
            if ($all) echo(json_encode($all));
        }
    }
}
?>
