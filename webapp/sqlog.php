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
        if ($all) return($all);
    }
}

function where($utime){
    $tol =43200000;
    if($utime){
        return ' WHERE time BETWEEN '.($utime - $tol).' AND '.($utime + $tol);
    }else{
        return ' ORDER BY time DESC LIMIT 24';
    }
}
function mk_query($vid,$tbl,$opt){
     global $site, $opt;

}
function get_data($vid){
    global $site, $opt;
    $fname='/var/www/html/log/sqlog_'.$site.'.sq3';
    $pdo=new PDO('sqlite:'.$fname);
    if(!$pdo) return;
    $tbls = get_tbl($pdo);
    if(!$tbls) return;
    $qrys=array();
    foreach($tbls as &$tbl){
        array_push($qrys, 'SELECT time,' . $vid . ' FROM ' . $tbl);
    }
    $qry = join(' union ', $qrys) . $opt;
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
$opt = where($utime);

echo(json_encode(array_map('get_data', split(',',$vids))));
?>
