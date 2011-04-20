#!/bin/bash
. ~/lib/libcsv.sh
devices=${1:-`ls ~/.var/device_???_*|cut -d_ -f2`};shift
cmd="${*:-getstat}"
for id in $devices; do
    setfld $id || _usage_key
    echo "#### $dev($id) ####"
    frmcmd $dev $id $cmd | visi
done
