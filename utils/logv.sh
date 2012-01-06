#!/bin/bash
while read time id data; do
    time=`date -d @$time +"%F %X"`
    echo "$time [$id] "
    echo $data|base64 -d|hd
done
