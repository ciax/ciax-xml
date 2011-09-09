#!/bin/bash
. ~/lib/libcsv.sh
id=$1;shift
day=$1;shift
setfld $id || _usage_key
input="$HOME/.var/device_${id}_*.log"
field="$HOME/.var/field_${id}.json"
rdb="$HOME/.var/ciax.sq3"
sql="sqlite3 $rdb"
[ -e $rdb ] || <$field appstat $app |logsql -c $id | $sql
trap "exit" SIGINT
cat $input | cutlog ${day:-2011/1/1} - | while read -r line ;do
    set - $line
    if echo "$line" | frmupd $id ; then
        ruby -e "print Time.at($1)"
        echo -n " : ${2#*:} : "
        <$field appstat $app | logsql $id | $sql >/dev/null 2>&1 && echo "OK" || echo "SKIP"
    fi
    read -u 1 -t 0 && break
done
