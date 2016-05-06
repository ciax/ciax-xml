<?php
$array=array();
foreach(glob("record*.json") as $url){
    $json=file_get_contents($url);
    $obj=json_decode($json,true);
    $line=array($obj["id"],$obj["cid"],$obj["result"]);
    array_push($array,$line);
 }
print(json_encode($array, JSON_PRETTY_PRINT));
?>
