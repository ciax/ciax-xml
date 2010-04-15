#!/bin/bash
. ~/se/lib/libdb.sh cx_class
cls=${1:-det}
cmd=${2:-upd}
dev=$(lookup $cls dev) || _usage_key
input=~/.var/${dev}.mar
[ -e $input ] || _die "no input file"
output=~/.var/${cls}.mar
clsctrl $cls $cmd < $output
[ "$cmd" = upd ] || exit
clsstat $cls < $input > $output || exit
[ "$VER" ] && mar $output || stv $output
