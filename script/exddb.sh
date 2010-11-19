#!/bin/bash
. ~/lib/libcsv.sh
devices=${1:-cf1 crt det dts cci mh1 mt3 mix map mma ml1};shift
default="${*:-getstat}"
for id in $devices; do
    setfld $id || _usage_key
    echo "#### $dev($id) ####"
    input="$HOME/.var/device_${id}_2010.log"
    output="$HOME/.var/field_${id}.json"
    link="$HOME/.var/field_${dev}.json"
    cmd=$default
    { devcmd $dev $id $cmd || exit 1; } | visi
    [ "$default" = 'getstat' ] && [ -e $output ] && rm $output
    stat="`grep rcv:${cmd// /:} $input|tail -1`"
    if [ "$stat" ] ; then
        echo " *** Stat ***"
        echo "$stat" | devstat $dev $id
        echo
        ln -sf $output $link
    fi
    read -n 1
done
