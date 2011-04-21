#!/bin/bash
. ~/lib/libcsv.sh
devices=${1:-`ls ~/.var/device_???_*|cut -d_ -f2`};shift
for id in $devices; do
    setfld $id || _usage_key
    echo "#### $dev($id) ####"
    if [ "$1" ] ; then
        frmcmd $dev $id $* | visi
    else
        frmcmd $dev $id 2>&1 |grep : | while read line; do
            cmd=${line%:*}
            echo -n "   $cmd ";frmcmd $dev $id $cmd 1 0| visi
        done
    fi
done
