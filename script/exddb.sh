#!/bin/bash
. ~/lib/libcsv.sh
devices=${1:-`ls ~/.var/device_???_*|cut -d_ -f2`};shift
default="${*:-getstat}"
for id in $devices; do
    setfld $id || _usage_key
    echo "#### $dev($id) ####"
    input="$HOME/.var/device_${id}_2010.log"
    output="$HOME/.var/field_${id}.json"
    cmd=$default
    { devcmd $dev $id $cmd || exit 1; } | visi
    [ "$default" = 'getstat' ] && [ -e $output ] && rm $output
    stat="`grep rcv:${cmd// /:} $input|tail -1`"
    if [ "$stat" ] ; then
        echo " *** Stat ***"
        echo "$stat" | devstat $dev $id
        echo
    fi
    read -n 1
done
