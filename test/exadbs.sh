#!/bin/bash
. ~/lib/libdb.sh entity
[[ "$1" == -* ]] && { opt=$1; shift; }
[ "$opt" ] && rm ~/.var/json/status*
ids=${1:-`ls ~/.var/json/field_???.json|cut -d_ -f2|cut -d. -f1`};shift
par="$*"
for id in $ids; do
    echo "$C2#### $id ####$C0"
    file=$HOME/.var/json/field_$id.json
    ~/lib/libapprsp.rb < $file
    ~/lib/libappsym.rb $id > /dev/null
    read -t 0 && break
done
