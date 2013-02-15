#!/bin/bash
. ~/lib/libdb.sh entity
id=$1;shift
IFS=':' cmd="$*"
setfld $id || _usage_key '' "[cmd]"
input="$HOME/.var/stream_${id}_*.log"
for i in $input;do
    egrep -h "rcv" $i|egrep "${cmd:-.}"
done | tail -1 | grep .
