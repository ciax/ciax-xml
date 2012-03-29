#!/bin/bash
. ~/lib/libdb.sh entity
[[ "$1" == -* ]] && { opt=$1; shift; }
[ "$opt" ] && rm ~/.var/json/view*
ids=${1:-`ls ~/.var/json/field_???.json|cut -d_ -f2|cut -d. -f1`};shift
par="$*"
for id in $ids; do
    view=$HOME/.var/json/view_$id.json
    [ -e $view ] || continue
    echo "$C2#### $id ####$C0"
    if [ "$opt" ]
    then
        v2s <$view
    else
        ~/lib/libappprt.rb < $view
    fi
    read -t 0 && break
done
