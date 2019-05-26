<?php
#Get Log value from Sqlog
# Args: site,vid,range,time.
# if no range, returns all range.
# if no time, time is now.
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
    # split is obsolete at PHP7. use explode
    $ary=explode("=",$e);
  if(count($ary)>1){
    $args[$ary[0]]=$ary[1];
  }
}
function get_tbl($pdo){
  $tbl = 'SELECT tbl_name FROM sqlite_master WHERE type="table"';
  $st=$pdo->query($tbl);
  if ($st){
    $all=$st->fetchAll(PDO::FETCH_COLUMN);
    if ($all) return($all);
  }
}
function mk_body($tbls, $vid){
  $qrys=array();
  foreach($tbls as &$tbl){
    array_push($qrys, 'SELECT time,' . $vid . ' FROM ' . $tbl);
  }
  return join(' union ', $qrys);
}
function get_data($vid){
  global $site, $utime;
  $fname='/var/www/html/log/sqlog_'.$site.'.sq3';
  $pdo=new PDO('sqlite:'.$fname);
  if(!$pdo) return;
  $tbls = get_tbl($pdo);
  if(!$tbls) return;
  $body=mk_body($tbls,$vid);
  $qry = 'select * from (' . $body . ') order by time desc limit ';
  if($utime){
    $qry .= '1000 offset ( select count(time) from (' . $body . ') where time >'. $utime . ') - 500';
  }else{
    $qry .= '24';
  }
  $st=$pdo->query($qry);
  if (!$st) return;
  $data=$st->fetchAll(PDO::FETCH_NUM);
  if (!$data) return;
  $dset = array('label' => "$site:$vid", 'vid' => $vid);
  $dset['data'] = $data;
  return $dset;
}

$site=getarg('site');
$vids=getarg('vid');
# No time -> now
$utime=getarg('time');

echo(json_encode(array_map('get_data', explode(',',$vids))));
?>
