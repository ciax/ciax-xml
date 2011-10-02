#!/bin/bash
. ~/lib/libcsv.sh
id2frm(){
    frm=`~/lib/libinsdb.rb -a $1 | grep 'frm_type'` || return 1
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
        echo -ne "${C3}process $cmd $par$C0\t"
        logline $id $cmd $par > $temp
        VER=$ver < $temp $frmrsp $frm $id|merging $output
        cut -f3 $temp|grep . || echo
    done
}
frmcmd=~/lib/libfrmcmd.rb
frmrsp=~/lib/libfrmrsp.rb
temp=`mktemp`
trap "rm $temp" EXIT
ver=$VER;unset VER
ids=$1;shift
cmds=$1;shift
par=$*
for id in ${ids:-`getid`}; do
    frm=`id2frm $id` || continue
    echo "$C2#### $frm($id) ####$C0"
    output="$HOME/.var/json/field_${id}.json"
    echo -n "{'id':'$id'}"|merging $output
    getstat ${cmds:-`getcmd $frm`}
    v2s $output
    read -t 0 && break
done

