#!/bin/bash
. ~/se/lib/libdb.sh cx_object
obj="$1"
iskey $obj || _usage_key
iocmd=`lookup "$obj" iocmd` || _die "No entry in iocmd field"
cls=`lookup "$obj" cls`
setdb cx_class
dev=`lookup "$cls" dev`
echo " [$iocmd]" >&2 
devshell $dev "$iocmd"