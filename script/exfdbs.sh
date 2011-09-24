#!/bin/bash
. ~/lib/libcsv.sh
id2dev(){
    dev=`~/lib/libentdb.rb $1 - | grep 'frm_type'` || return 1
    echo $dev|cut -d: -f2|tr -d ' "'
}
getid(){
    ls ~/.var/device_???_*|cut -d_ -f2|sort -u
}
getcmd(){
    $frmcmd $1 2>&1 |grep "^ "|cut -d: -f1
}
frmcmd=~/lib/libfrmcmd.rb
frmrsp=~/lib/libfrmrsp.rb
ver=$VER;unset VER
i=$1;shift
for id in ${i:-`getid`}; do
    dev=`id2dev $id` || continue
    echo "$C2#### $dev($id) ####$C0"
    output="$HOME/.var/field_${id}.json"
    echo -n "{'id':'$id'}"|merging $output
    i=$1;shift
    for cmd in ${i:-`getcmd $dev`}; do
        echo "${C3}process $cmd $*$C0"
        [ "$ver" ] && VER=$ver
        logline $id $cmd $* | $frmrsp -q $dev|merging $output
        unset VER
    done
    v2s $output
    read -t 0 && break
done

