#!/bin/bash
. ~/lib/libcsv.sh
[[ "$1" == -* ]] && { opt=$1; shift; }
[ "$opt" ] && rm ~/.var/cache/*
[ "$1" ] && { setfld $1 || _usage_key "(-lgsc)"; }
devices=${1:-`ls ~/.var/field_???.json|cut -d_ -f2|cut -d. -f1`};shift
par="$*"
for id in $devices; do
    setfld $id || continue
    echo "$C2#### $cls($id) ####$C0"
    file=$HOME/.var/field_$id.json
    clsstat $cls < $file | viewing $opt $obj | if [ "$opt" ]
    then
        v2s
    else
        stprint
    fi
    read -t 0 && break
done
