#!/bin/bash
_id2frm(){
    exp="$(grep $1 ~/ciax-xml/ddb*.xml|tr ' ' '\n'|grep frm_id)"||return 1
    eval "$exp"
}
_getdid(){
    ls ~/.var/log/stream_???_*|cut -d_ -f2|sort -u
}
_getcmd(){
    grep '<item' ~/ciax-xml/fdb-$1.xml|tr ' ' '\n'|grep 'id='|egrep -o '[a-z]{3}'
}
_getstat(){
    local c
    for cmd; do
        echo -ne "${C3}process $cmd $par$C0\t"
        json_logpick $did $cmd $par > $temp || { echo; continue; }
#        VER=$ver < $temp libfrmconv -m || return 1
        [ "$c" = 'ccc' ] && { c=''; echo; } || c="c$c"
    done
}
temp=$(mktemp)
trap "rm $temp" EXIT
ver=$VER;unset VER
ids=$1;shift
cmds=$1;shift
par=$*
for did in ${ids:-$(_getdid)}; do
    _id2frm $did || continue
    echo "$C2#### $frm_id($did) ####$C0"
    output="$HOME/.var/json/field_${did}.json"
    _getstat ${cmds:-$(_getcmd $frm_id)} || break
    [ -e $output ] && json_view $output
    read -t 0 && break
done
