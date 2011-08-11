#!/bin/bash
. ~/lib/libcsv.sh
id=$1;shift
setfld $id || _usage_key
input="$HOME/.var/device_${id}_*.log"
field="$HOME/.var/field_${id}.json"
sql="sqlite3 $HOME/.var/ciax.sq3"
<$field clsstat $cls |logsql -c $id | $sql
egrep -h "rcv:$cmd" $input | while read -r line ;do
    set - $line
    if echo "$line" | frmstat -q $dev | merging $field ; then
        echo "${2#*:}"
        <$field clsstat $cls | logsql $id | $sql >/dev/null 2>&1
    fi
done
