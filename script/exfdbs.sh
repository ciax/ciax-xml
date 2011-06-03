#!/bin/bash
. ~/lib/libcsv.sh
[[ "$1" == -* ]] && { opt=$1;shift; }
getstat(){
    cmd="$*"
    echo "${C3}process for $cmd$C0"
    logline $id $cmd | frmstat $dev | merging $output
}

devices=${1:-`ls ~/.var/device_???_*|cut -d_ -f2`};shift
par="$*"
for id in $devices; do
    setfld $id || _usage_key "(-ls)"
    echo "$C2#### $dev($id) ####$C0"
    input="$HOME/.var/device_${id}_*.log"
    output="$HOME/.var/field_${id}.json"
    [ "$clear" ] && [ -e $output ] && rm $output
    if [ "$par" ] ; then
        frmcmd $dev $par > /dev/null || continue
        getstat $par
    else
        VER= frmcmd $dev $id 2>&1 |grep ' : '|while read cmd dmy
        do
            getstat $cmd
        done
    fi
    VER= < $output viewing $opt | if [ "$opt" ]
    then
        v2s
    else
        stprint
    fi
done
