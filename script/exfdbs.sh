#!/bin/bash
. ~/lib/libcsv.sh
[ "$1" = "-r" ] && { shift; clear=1; }
[ "$1" = "-s" ] && { shift; sym=1; }
[ "$1" = "-l" ] && { shift; label=1; }
[ "$1" = "-p" ] && { shift; print=1; }
devices=${1:-`ls ~/.var/device_???_*|cut -d_ -f2`};shift
cmd=$*
for id in $devices; do
    setfld $id || _usage_key "(-r|-s)"
    echo "$C2#### $dev($id) ####$C0"
    input="$HOME/.var/device_${id}_*.log"
    output="$HOME/.var/field_${id}.json"
    [ "$clear" ] && [ -e $output ] && rm $output
    if [ "$cmd" ] ; then
        echo ${cmd// /:}
    else
        frmcmd $dev $id 2>&1 |grep " : "
    fi | while read cmd dmy; do
        stat="`egrep 'rcv:$cmd[ :]' $input|tail -1`"
        if [ "$stat" ] ; then
            echo "process for $cmd ($stat)"
            echo "$stat" | frmstat $dev $id
        fi
    done
    if [ "$print" ] ; then
        < $output symboling | labeling | stprint
    elif [ "$label" ] ; then
        < $output labeling | h2s
    elif [ "$sym" ] ; then
        < $output symboling | h2s
    else
        < $output h2s
    fi
done
