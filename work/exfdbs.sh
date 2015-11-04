#!/bin/bash
_id2frm(){
    eval "$(grep $1 ~/ciax-xml/ddb*.xml|tr ' ' '\n'|grep frm_id)"||return
}
_getdid(){
    ls ~/.var/stream_???_*|cut -d_ -f2|sort -u
}
_getcmd(){
    eval "$(grep '<item' ~/ciax-xml/fdb-$1.xml|tr ' ' '\n'|grep 'id=')"
}
_getstat(){
    for cmd; do
        echo -ne "${C3}process $cmd $par$C0\t"
        sqlog-json $id $cmd $par > $temp || { echo; continue; }
        VER=$ver < $temp libfrmrsp -m || return 1
    done
}
temp=$(mktemp)
trap "rm $temp" EXIT
ver=$VER;unset VER
ids=$1;shift
cmds=$1;shift
par=$*
for did in ${ids:-$(_getdid)}; do
    _id2frm $did
    echo "$C2#### $frm_id($did) ####$C0"
    output="$HOME/.var/json/field_${did}.json"
    _getstat ${cmds:-$(_getcmd $frm_id)} || break
    [ -e $output ] && json_view $output
    read -t 0 && break
done

