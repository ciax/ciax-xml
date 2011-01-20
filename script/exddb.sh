#!/bin/bash
. ~/lib/libcsv.sh
[ "$1" = "-r" ] && { shift; clear=1; }
[ "$1" = "-v" ] && { shift; view=1; }
devices=${1:-`ls ~/.var/device_???_*|cut -d_ -f2`};shift
default="${*:-getstat}"
for id in $devices; do
    setfld $id || _usage_key
    echo "#### $dev($id) ####"
    input="$HOME/.var/device_${id}_*.log"
    output="$HOME/.var/field_${id}.json"
    cmd=$default
    { devcmd $dev $id $cmd || exit 1; } | visi
    [ "$clear" ] && [ -e $output ] && rm $output
    stat="`grep rcv:${cmd// /:} $input|tail -1`"
    if [ "$stat" ] ; then
        echo " *** Stat ***"
        if [ "$view" ] ; then
            echo "$stat" | devstat $dev $id | stview
        else
            echo "$stat" | devstat $dev $id
            echo
        fi
    fi
    read -n 1
done
