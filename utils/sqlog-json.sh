#!/bin/bash
[ "$1" = '-s' ] && { dir='snd';shift; }
id=$1;shift
fname="$HOME/.var/sqlog_${id}.sq3"
if [ ! -e $fname ] ; then
    echo -n "Usage: sqlog-json (-s) ("
    for i in ~/.var/sqlog_*.sq3; do
        j=${i#*_}
        echo -n $s0${j%.*}
        s0=/
    done
    echo ") [cmd]"
    exit
fi
sqlog="sqlite3 -line $fname"
cmd=$1;shift
[ "$cmd" ] && subcmd='and cmd = "'$cmd'"'
subdir='dir = "'${dir:-rcv}'"'
table=$(echo ".table"|$sqlog|tr " " "\n"|grep stream)
pick="select max(time) from $table where $subdir $subcmd"
last="select * from $table where time = ($pick);"
echo -n "{"
echo "$last"|$sqlog|while read i ; do
    set - $i
    echo -n $sep'"'$1'"':'"'$3'"'
    sep=,
done
echo "}"