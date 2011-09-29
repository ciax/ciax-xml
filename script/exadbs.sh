#!/bin/bash
. ~/lib/libcsv.sh
[[ "$1" == -* ]] && { opt=$1; shift; }
[ "$opt" ] && rm ~/.var/json/status*
ids=${1:-`ls ~/.var/field_???.json|cut -d_ -f2|cut -d. -f1`};shift
par="$*"
for id in $ids; do
    aline=`~/lib/libinsdb.rb $id|tr -d '"'|grep app` || continue
    app=${aline#*:}
    echo "$C2#### $app($id) ####$C0"
    file=$HOME/.var/field_$id.json
    stat=$HOME/.var/json/status_$id.json
    ~/lib/libappstat.rb $app < $file > $stat
    if [ "$opt" ]
    then
        v2s <$stat
    else
        ~/lib/libprint.rb $stat
    fi
    read -t 0 && break
done
