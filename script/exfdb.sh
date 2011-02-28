#!/bin/bash
. ~/lib/libcsv.sh
[ "$1" = "-r" ] && { shift; clear=1; }
[ "$1" = "-s" ] && { shift; sym=1; }
devices=${1:-`ls ~/.var/device_???_*|cut -d_ -f2`};shift
default="${*:-getstat}"
for id in $devices; do
    setfld $id || _usage_key "(-r|-s)"
    echo "#### $dev($id) ####"
    input="$HOME/.var/device_${id}_*.log"
    output="$HOME/.var/field_${id}.json"
    cmd=$default
    { devcmd $dev $id $cmd || exit 1; } | visi
    [ "$clear" ] && [ -e $output ] && rm $output
    stat="`grep rcv:${cmd// /:} $input|tail -1`"
    if [ "$stat" ] ; then
        echo " *** Stat ***"
        if [ "$sym" ] ; then
            echo "$stat" | devstat $dev $id | symconv
        else
            echo "$stat" | devstat $dev $id
            echo
        fi
    fi
done
