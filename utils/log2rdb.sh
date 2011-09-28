#!/bin/bash
. ~/lib/libcsv.sh
id=$1;shift
day=$1;shift
setfld $id || _usage_key '' '(date)'
appstat=~/lib/libappstat.rb
frmrsp=~/lib/libfrmrsp.rb
input="$HOME/.var/device_${id}_*.log"
field="$HOME/.var/field_${id}.json"
rdb="$HOME/.var/ciax.sq3"
sql="sqlite3 $rdb"
temp=`mktemp`
trap "rm $temp" EXIT
$sql '.tables'|grep $id || <$field $appstat $app |logsql -c $id > $temp
echo "begin;" >> $temp
logcut $id ${day:-2011/1/1} - | while read -r line ;do
    set - $line
    echo "$line"|$frmrsp $dev 2>/dev/null | merging $field || continue
    ruby -e "print Time.at($1)"
    echo " : $2"
    <$field $appstat $app|logsql $id >> $temp
    read -u 1 -t 0 && break
done
echo "commit;" >> $temp
<$temp $sql

