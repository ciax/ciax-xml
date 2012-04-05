#!/bin/bash
. ~/lib/libdb.sh entity
[[ "$1" == -* ]] && { opt=$1; shift; }
[ "$opt" ] && rm ~/.var/json/status*
ids=${1:-`ls ~/.var/json/field_???.json|cut -d_ -f2|cut -d. -f1`};shift
par="$*"
for id in $ids; do
    echo "$C2#### $id ####$C0"
    aline=`~/lib/libinsdb.rb $id|tr -d '"'|grep app` || continue
    app=${aline#*:}
    file=$HOME/.var/json/field_$id.json
    ~/lib/libappstat.rb $app < $file
    read -t 0 && break
done
