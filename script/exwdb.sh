#!/bin/bash
n=${1:-*}
file=$HOME/.var/json/status_$n.json
for i in $file ; do
    _msg `basename $i`
    watches < $i
    read -t 0 && break
done
