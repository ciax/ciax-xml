#!/bin/bash
# Record list specified by cid
# Usage: cids (serch word)
#alias cids
get_date(){
    [[ $1 =~ [0-9] ]] && date -d +@${1:0:10} || echo "$1"
}
search=${1:-.}
IFS=:
while read fpath tag val;do
    utime=${fpath#*_}
    utime=${utime%.*}
    if [[ $tag == *cid* ]]; then
        echo -n "$(get_date $utime) $val"
    elif [ "$crnt" != "$utime" ]; then
        echo " -> $val"
        crnt=$utime
    fi
done < <(egrep -o -e '"cid":[^,]*' -e '"result":[^,]*' ~/.var/json/record*) | grep $search
