#!/bin/bash
. ~/se/lib/libdb.sh cx_object
obj=${1:-cci}
cmd=${2:-upd}
cls=$(lookup $obj cls) || _usage_key
input=~/.var/${cls}.mar
[ -e $input ] || _die "no input file"
output=~/.var/${obj}.mar
objctrl $obj $cmd || exit
[ "$cmd" = upd ] || exit
objstat $obj < $input > $output || exit
[ "$VER" ] && mar $output || stv $output
