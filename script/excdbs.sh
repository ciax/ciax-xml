#!/bin/bash
. ~/lib/libcsv.sh
[ "$1" = '-s' ] && { sym=1; shift; }
[ "$1" = '-l' ] && { label=1; shift; }
[ "$1" = '-r' ] && { reverse=1; shift; }
[ "$1" = '-p' ] && { print=1; shift; }
devices=${1:-`ls ~/.var/field_???.json|cut -d_ -f2|cut -d. -f1`};shift
par="$*"
for id in $devices; do
    setfld $id || _usage_key "(-slrp)"
    echo "$C2#### $cls($id) ####$C0"
    file=$HOME/.var/field_$id.json
    if [ "$print" ] ; then
        clsstat $cls < $file | symboling | labeling | grouping | stprint
    elif [ "$reverse" ] ; then
        clsstat $cls < $file | labeling | symboling | v2s
    elif [ "$label" ] ; then
        clsstat $cls < $file | labeling | grouping | v2s
    elif [ "$sym" ] ; then
        clsstat $cls < $file | symboling | v2s
    else
        clsstat $cls < $file | h2s
    fi
done
