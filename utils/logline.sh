#!/bin/bash
. ~/lib/libdb.sh entity
id=$1;shift
IFS=':' cmd="$*"
setfld $id || _usage_key '' "[cmd]"
input="$HOME/.var/frame_${id}_*.log"
for i in $input;do
    egrep -h "rcv:$cmd" $i
done | tail -1 | grep .
