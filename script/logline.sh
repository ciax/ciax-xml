#!/bin/bash
. ~/lib/libcsv.sh
id=$1;shift
IFS=':' cmd="$*"
setfld $id || _usage_key '' "[cmd]"
frmcmd $dev $id $cmd > /dev/null || exit
input="$HOME/.var/device_${id}_*.log"
egrep "rcv:$cmd" $input|tail -1|cut -f3
