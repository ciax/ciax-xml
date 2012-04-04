#!/bin/bash
. ~/lib/libdb.sh entity
id2frm(){
    frm=`~/lib/libinsdb.rb -a $1 | grep 'frm_type'` || return 1
    echo $frm|cut -d: -f2|tr -d ' "'
}
getid(){
    ls ~/.var/frame_???_*|cut -d_ -f2|sort -u
}
getcmd(){
    $frmcmd $1 2>&1 |grep "^ "|cut -d: -f1
}
getstat(){
    for cmd; do
        echo -ne "${C3}process $cmd $par$C0\t"
        logline $id $cmd $par > $temp || { echo; continue; }
        VER=$ver < $temp $frmrsp $frm || return 1
        cut -f3 $temp|grep .|base64 -d|visi || echo
    done
}
frmcmd="$HOME/lib/libfrmcmd.rb"
frmrsp="$HOME/lib/libfrmrsp.rb -m"
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
    merging $output <<EOF
{"id":"$id"}
EOF
    getstat ${cmds:-`getcmd $frm`} || break
    [ -e $output ] && v2s $output
    read -t 0 && break
done

