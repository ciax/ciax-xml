<?php
$cache="rec_list.json";
$list=file_get_contents($cache);
$array = $list ? json_decode($list,true) : array();
foreach(glob("record*.json") as $url){
    if(! ereg("[0-9]+",$url,$regs)) continue;
    if($array[(string)$regs[0]]) continue;
    $json=file_get_contents($url);
    $obj=json_decode($json,true);
    $array[(string)$obj["id"]]=array($obj["cid"],$obj["result"]);
}
krsort($array);
$json=json_encode($array, JSON_PRETTY_PRINT);
file_put_contents($cache, $json);
print($json);
?>
