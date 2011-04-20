#!/bin/bash
. ~/lib/libcsv.sh
[ "$1" = '-s' ] && { sym=1; shift; }
[ "$1" = '-l' ] && { label=1; shift; }
[ "$1" = '-p' ] && { print=1; shift; }
devices=${1:-`ls ~/.var/field_???.json|cut -d_ -f2|cut -d. -f1`};shift
cmd=${1:-upd};shift
par="$*"
for id in $devices; do
    setfld $id || _usage_key "(-s)"
    echo "#### $cls($id) ####"
    file=$HOME/.var/field_$id.json
    clscmd $cls $cmd $par < $file
    [ $cmd = 'upd' ] || continue
    echo " *** Status ***"
    if [ "$print" ] ; then
        clsstat $cls < $file | symboling | labeling | stprint
    elif [ "$label" ] ; then
        clsstat $cls < $file | symboling | labeling
    elif [ "$sym" ] ; then
        clsstat $cls < $file | symboling
    else
        clsstat $cls < $file
        echo
    fi
done
