#!/bin/bash
. ~/lib/libcsv.sh
frmcmd=~/lib/libfrmcmd.rb
[[ "$1" == -* ]] && { opt=$1;shift; }
[ "$opt" ] && rm ~/.var/cache/* ~/.var/field_???.json
getstat(){
    cmd="$*"
    echo "${C3}process $id for $cmd$C0"
    logline $id $cmd | if [ "$ver" ] ; then
        VER=$ver frmupd $id
    else
        frmupd $id
    fi
}

[ "$1" ] && { setfld $1 || _usage_key "(-ls)"; }
devices=${1:-`ls ~/.var/device_???_*|cut -d_ -f2|sort -u`};shift
par="$*"
ver=$VER;unset VER
for id in $devices; do
    setfld $id || continue
    echo "$C2#### $dev($id) ####$C0"
    input="$HOME/.var/device_${id}_*.log"
    output="$HOME/.var/field_${id}.json"
    [ "$clear" ] && [ -e $output ] && rm $output
    if [ "$par" ] ; then
        $frmcmd $dev 2>&1 |grep -q $par || continue
        getstat $par
    else
        $frmcmd $dev 2>&1 |grep ' : '|while read cmd dmy
        do
            getstat $cmd
        done
    fi
    < $output v2s
    read -t 0 && break
done
