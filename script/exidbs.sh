#!/bin/bash
. ~/lib/libdb.sh entity
[[ "$1" == -* ]] && { opt=$1; shift; }
[ "$opt" ] && rm ~/.var/json/stat_*
ids=${1:-`ls ~/.var/json/field_???.json|cut -d_ -f2|cut -d. -f1`};shift
par="$*"
for id in $ids; do
    stat=$HOME/.var/json/stat_$id.json
    [ -e $stat ] || continue
    echo "$C2#### $id ####$C0"
    if [ "$opt" ]
    then
        j2s <$stat
    else
        ~/lib/libview.rb < $stat
    fi
    read -t 0 && break
done
