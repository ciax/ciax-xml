#!/bin/bash
# Record viewer
#alias vr
[ "$1" == -r ] &&  { shift; opt=-r; }
if [ "$1" ] ; then
    records=$(find ~/.var/json/record* -size +1k)
    [ "$records" ] || exit
    line=$(( $2 + 1 ))
    file=$(grep -l "cid\": *\"$1\"" $records|tail -$line|head -1)
else
    file=~/.var/json/record_latest.json
fi
if [ -r "$file" ]; then
    librecord $opt < $file
    echo $file
else
    echo "Usage: ${0##*/} (cid) (history num)"
    egrep -ho "cid[^,]+" $records|cut -d: -f2|tr -d '" '|sort -u|column
fi
