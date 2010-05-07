#!/bin/bash
. ~/se/lib/libdb.sh cx_class
cls=${1:-crt}
cmd=${2:-upd}
dev=$(lookup $cls dev) || _usage_key
output=~/.var/${cls}.mar
objcmd $cls $cmd
[ "$cmd" = upd ] || exit
objstat $cls | { [ "$VER" ] && mar || stv; }



