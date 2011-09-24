#!/bin/bash
. ~/lib/libcsv.sh
id2frm(){
    frm=`~/lib/libentdb.rb $1 - | grep 'frm_type'` || return 1
    echo $frm|cut -d: -f2|tr -d ' "'
}
getid(){
    ls ~/.var/device_???_*|cut -d_ -f2|sort -u
}
getcmd(){
    $frmcmd $1 2>&1 |grep "^ "|cut -d: -f1
}
getstat(){
    for cmd; do
        echo "${C3}process $cmd $par$C0"
        [ "$ver" ] && VER=$ver
        logline $id $cmd $par | tee >($frmrsp $frm|merging $output)
        unset VER
    done
}
frmcmd=~/lib/libfrmcmd.rb
frmrsp=~/lib/libfrmrsp.rb
ver=$VER;unset VER
ids=$1;shift
cmds=$1;shift
par=$*
for id in ${ids:-`getid`}; do
    frm=`id2frm $id` || continue
    echo "$C2#### $frm($id) ####$C0"
    output="$HOME/.var/field_${id}.json"
    echo -n "{'id':'$id'}"|merging $output
    getstat ${cmds:-`getcmd $frm`}
    v2s $output
    read -t 0 && break
done

