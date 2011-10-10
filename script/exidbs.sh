#!/bin/bash
. ~/lib/libcsv.sh
[[ "$1" == -* ]] && { opt=$1; shift; }
[ "$opt" ] && rm ~/.var/json/view*
ids=${1:-`ls ~/.var/json/field_???.json|cut -d_ -f2|cut -d. -f1`};shift
par="$*"
for id in $ids; do
    echo "$C2#### $id ####$C0"
    view=$HOME/.var/json/view_$id.json
    ~/lib/libwview.rb $id > $view
    if [ "$opt" ]
    then
        v2s <$view
    else
        ~/lib/libprint.rb < $view
    fi
    read -t 0 && break
done
