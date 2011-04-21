#!/bin/bash
. ~/lib/libcsv.sh
[ "$1" = "-r" ] && { shift; clear=1; }
[ "$1" = "-s" ] && { shift; sym=1; }
[ "$1" = "-l" ] && { shift; label=1; }
[ "$1" = "-p" ] && { shift; print=1; }
devices=${1:-`ls ~/.var/device_???_*|cut -d_ -f2`};shift
cmd=${*:-getstat}
for id in $devices; do
    setfld $id || _usage_key "(-r|-s)"
    echo "#### $dev($id) ####"
    input="$HOME/.var/device_${id}_*.log"
    output="$HOME/.var/field_${id}.json"
    [ "$clear" ] && [ -e $output ] && rm $output
    stat="`grep rcv:${cmd// /:} $input|tail -1`"
    if [ "$stat" ] ; then
        if [ "$print" ] ; then
            echo "$stat" | frmstat $dev $id | symboling | labeling | stprint
        elif [ "$label" ] ; then
            echo "$stat" | frmstat $dev $id | symboling | labeling
        elif [ "$sym" ] ; then
            echo "$stat" | frmstat $dev $id | symboling
        else
            echo "$stat" | frmstat $dev $id
            echo
        fi
    fi
done
