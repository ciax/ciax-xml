#!/bin/bash
# Record viewer
#alias vr
[ "$1" == -r ] &&  { shift; opt=-r; }
if [ "$1" ] ; then
    records=$(find ~/.var/json/record* -size +1k)
    [ "$records" ] || exit
    file=$(grep -l "cid\": *\"$1\"" $records|tail -1) || exit
else
    file=~/.var/json/record_latest.json
fi
echo
[ -r "$file" ] && librecord $opt < $file 
