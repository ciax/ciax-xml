#!/bin/bash
# Get Status by Date from SqLog
#alias sqld
id=$1;shift
date=$1;shift
fname="$HOME/.var/log/sqlog_${id}.sq3"
if [ ! -e $fname -o ! "$date" ] ; then
    echo -n "Usage: sqlog-date ("
    for i in ~/.var/log/sqlog_*.sq3; do
        j=${i#*_}
        echo -n $s0${j%.*}
        s0=/
    done
    echo ") [date]"
    exit
fi
sec=$(date -d $date +%s);
end=$(( sec + 86400 ))
table=$(echo ".table"|sqlite3 $fname|tr " " "\n"|grep status)
[ "$table" ] || { echo "No Stream DB for $id"; exit; }
echo select '*' from $table where time between $sec'000' and $end'000;'|sqlite3 -header $fname

