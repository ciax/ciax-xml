#!/bin/bash
. ~/lib/libcsv.sh
devices=${1:-cf1 crt det dts cci mh1 mt3 mix map mma ml1};shift
defcmd="${*:-getstat}"
for id in $devices; do
    export id
    dev=$(lookup $id dev) || _usage_key
    echo "#### $dev($id) ####"
    input="$HOME/.var/device_${id}_2010.log"
    output="$HOME/.var/field_${id}.mar"
    link="$HOME/.var/field_${dev}.mar"
    cmd=$defcmd
    { devcmd $dev $cmd || exit 1; } | visi
    [ "$defcmd" = 'getstat' ] && rm $output
    stat="`grep rcv:${cmd// /:} $input|tail -1`"
    [ "$stat" ] && echo "$stat" | devstat $dev $cmd|mar
    ln -sf $output $link
    read -n 1
done
