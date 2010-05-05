#!/bin/bash
. ~/se/lib/libdb.sh cx_object
obj="$1"
iskey $obj || _usage_key
rem=`lookup "$obj" remote` || _die "No entry in remote field"
lookup "$obj" np|grep udp >& /dev/null && NP='-u '
dump=~/.var/$obj.dmp
file=~/.var/$obj.bin
host=${rem%:*}
port=${rem#*:}
echo " [nc $NP$host $port]" >&2 
nc -q 0 -o $dump -w 1 $NP$host $port | tee $file
