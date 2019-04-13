#!/bin/bash
[[ "$1" == -* ]] && { opt=$1; shift; }
[ "$opt" ] && rm ~/.var/json/status*
PROJ=
ids=${1:-`ls ~/.var/json/field_???.json|cut -d_ -f2|cut -d. -f1`};shift
par="$*"
for id in $ids; do
    echo "$C2#### $id ####$C0"
    file=$HOME/.var/json/field_$id.json
    libappconv < $file || exit
    libappsym $id > /dev/null || exit
    read -t 0 && break
done
