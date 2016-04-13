#!/bin/bash
# Record list specified by cid
#alias cids
get_date(){
    str=${1#*_}
    str=${str%.*}
    [[ $str =~ [0-9] ]] && date -d +@${str:0:10}|tr -d '\n' || echo $str
}
IFS=:
while read fpath sep cid;do
    echo "$(get_date $fpath) $cid"
done < <(egrep -o '"cid":[^,]*' ~/.var/json/record*)
                                   
