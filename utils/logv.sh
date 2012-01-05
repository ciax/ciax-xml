#!/bin/bash
while read time id data; do
    time=`date -d @$time +"%F %X"`
    echo -n "$time [$id] "
    echo $data|base64 -d|visi
done
