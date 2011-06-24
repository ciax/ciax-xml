#!/bin/bash
. ~/lib/libcsv.sh
id=$1;shift
IFS=':' cmd="$*"
setfld $id || _usage_key '' "[cmd]"
input="$HOME/.var/device_${id}_*.log"
egrep -h "rcv:$cmd" $input|tail -1
