#!/bin/bash
#alias jlp
[ "$1" = '-s' ] && { dir='snd';shift; }
[ "$1" ] || { echo "Usage: ${0##*/} (-s:snd) [site] (cmd:par)"; exit 1; }
id=$1;shift
cmd=$1;shift
# The number counting from behind
num=$1;shift
input=
latest=''
for i in "$HOME/.var/log/stream_${id}_*.log"; do
    [ "$latest" ] && [ "$latest" -nt "$i" ] && continue
    latest=$i
done
[ "$latest" ] || exit
tail -n 1000 $latest | egrep -h "${dir:-rcv}" |\
egrep "\"${cmd:-.}\"" | tail -${num:-1} | head -1
