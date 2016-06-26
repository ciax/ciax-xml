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
        if ($all) return(join(',',$all));
    }
}

function where($range, $utime){
    if (!$range) return '';
    if($utime){
        $min=$utime - $range;
        $max=$utime - 0 + $range;
        return ' WHERE time BETWEEN '.$min.' and '.$max;
    }else{
        return ' WHERE time > '.(time().'000' - $range);
    }
}
function get_data($vid){
    global $site, $opt;
    $fname='/var/www/html/log/sqlog_'.$site.'.sq3';
    $pdo=new PDO('sqlite:'.$fname);
    if(!$pdo) return;
    $tbls = get_tbl($pdo);
    if(!$tbls) return;
    $qry = 'SELECT time,' . $vid . ' FROM ' . $tbls . $opt;
    $st=$pdo->query($qry);
    if (!$st) return;
    $data=$st->fetchAll(PDO::FETCH_NUM);
    if (!$data) return;
    $dset = array('label' => "$site:$vid");
    $dset['data'] = $data;
    return $dset;
}

$site=getarg('site');
$vid=getarg('vid');
# No range -> whole
$range=getarg('range');
# No time -> now
$utime=getarg('time');
$opt = where($range,$utime);

echo(json_encode(array_map('get_data', split(',',$vid))));
?>
