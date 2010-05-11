#!/bin/bash
. ~/se/lib/libdb.sh cx_object
obj=${1:-crt}
cmd=${2:-upd}
dev=$(lookup $obj dev) || _usage_key

objcmd $obj $cmd
[ "$cmd" = upd ] || exit
objstat $obj | { [ "$VER" ] && mar || stv; }



