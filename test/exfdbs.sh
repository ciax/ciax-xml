#!/bin/bash
. ~/lib/libdb.sh entity
_id2frm(){
    frm=`~/lib/liblocdb.rb $1 frm| grep \"id` || return 1
    echo $frm|cut -d: -f2|tr -d ' "'
}
_getid(){
    ls ~/.var/stream_???_*|cut -d_ -f2|sort -u
}
_getcmd(){
    $frmcmd $1 2>&1 |grep "^ "|cut -d: -f1
}
_getstat(){
    for cmd; do
        echo -ne "${C3}process $cmd $par$C0\t"
        logline $id $cmd $par > $temp || { echo; continue; }
        VER=$ver < $temp $frmrsp -ml || return 1
    done
}
frmcmd="$HOME/lib/libfrmcmd.rb"
frmrsp="$HOME/lib/libfrmrsp.rb"
temp=`mktemp`
trap "rm $temp" EXIT
ver=$VER;unset VER
ids=$1;shift
cmds=$1;shift
par=$*
for id in ${ids:-`_getid`}; do
    frm=`_id2frm $id` || continue
    echo "$C2#### $frm($id) ####$C0"
    output="$HOME/.var/json/field_${id}.json"
    json_merge $output <<EOF
{"id":"$id"}
EOF
    _getstat ${cmds:-`_getcmd $frm`} || break
    [ -e $output ] && j2s $output
    read -t 0 && break
done

