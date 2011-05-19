#!/bin/bash
. ~/lib/libcsv.sh
[ "$1" = "-r" ] && { shift; clear=1; }
[ "$1" = "-s" ] && { shift; sym=1; }
[ "$1" = "-l" ] && { shift; label=1; }
[ "$1" = "-p" ] && { shift; print=1; }

getstat(){
    cmd="$*"
    echo "${C3}process for $cmd$C0"
    logline $id $cmd | frmstat $dev | merging $output
}

devices=${1:-`ls ~/.var/device_???_*|cut -d_ -f2`};shift
par="$*"
for id in $devices; do
    setfld $id || _usage_key "(-rslp)"
    echo "$C2#### $dev($id) ####$C0"
    input="$HOME/.var/device_${id}_*.log"
    output="$HOME/.var/field_${id}.json"
    [ "$clear" ] && [ -e $output ] && rm $output
    if [ "$par" ] ; then
        getstat $par
    else
        frmcmd $dev $id 2>&1 |grep ' : '|while read cmd dmy; do
            getstat $cmd
        done
    fi
    if [ "$print" ] ; then
        < $output symboling | labeling | stprint
    elif [ "$label" ] ; then
        < $output labeling | v2s
    elif [ "$sym" ] ; then
        < $output symboling | v2s
    else
        < $output h2s
    fi
done
