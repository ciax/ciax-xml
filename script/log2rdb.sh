#!/bin/bash
. ~/lib/libcsv.sh
id=$1;shift
setfld $id || _usage_key
input="$HOME/.var/device_${id}_*.log"
field="$HOME/.var/field_${id}.json"
rdb="$HOME/.var/ciax.sq3"
sql="sqlite3 $rdb"
[ -e $rdb ] || <$field appstat $cls |logsql -c $id | $sql
trap "exit" SIGINT
egrep -h "rcv:$cmd" $input | while read -r line ;do
    set - $line
    if echo "$line" | frmupd $id ; then
        echo -n "${2#*:} : "
        <$field appstat $cls | logsql $id | $sql >/dev/null 2>&1 && echo "OK" || echo "SKIP"
    fi
done
