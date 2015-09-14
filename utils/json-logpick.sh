#!/bin/bash
[ "$1" = '-s' ] && { dir='snd';shift; }
[ "$1" ] || { echo "Usage: ${0##*/} (-s:snd) [site] (cmd:par)"; exit 1; }
id=$1;shift
IFS=':' cmd="$*"
input="$HOME/.var/log/stream_${id}_*.log"
for i in $input;do
    egrep -h "${dir:-rcv}" $i|egrep "${cmd:-.}"
done | tail -1
