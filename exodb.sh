#!/bin/bash
. ~/se/lib/libdb.sh cx_object
obj=${1:-cci}
cls=$(lookup $obj cls) || _usage_key
input=~/.var/${cls}.mar
[ -e $input ] || _die "no input file"
output=~/.var/${obj}.mar
objstat $obj < $input > $output &&
[ "$VER" ] && mar $output || stv $output
