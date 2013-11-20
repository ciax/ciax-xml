#!/bin/bash
. ~/lib/libdb.sh entity
[ "$1" = '-s' ] && { dir='snd';shift; }
id=$1;shift
IFS=':' cmd="$*"
setfld $id || _usage_key '(-s)' "[cmd]"
input="$HOME/.var/stream_${id}_*.log"
for i in $input;do
    egrep -h "${dir:-rcv}" $i|egrep "${cmd:-.}"
done | tail -1 | grep .
