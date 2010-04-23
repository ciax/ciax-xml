#!/bin/bash
. ~/se/lib/libdb.sh cx_object
[ "$1" = '-d' ] && { dmy=1; shift; }
obj="$1"
iskey $obj || _usage_key "(-d)"
rem=`lookup "$obj" remote` || _die "No entry in remote field"
lookup "$obj" np|grep udp >& /dev/null && NP='-u '
file=~/.var/$obj.bin
host=${rem%:*}
port=${rem#*:}
echo " [nc $NP$host:$port]" >&2 
if [ "$dmy" ] ; then
    cat $file
else
    nc -q 0 -o ~/.var/$obj.dmp -w 1 $NP$host $port| tee $file
fi 
