#!/bin/bash
. ~/se/lib/libdb.sh cx_object
obj=${1:-cci}
cmd=${2:-upd}
cls=$(lookup $obj cls) || _usage_key
objcmd $obj $cmd || exit
[ "$cmd" = upd ] || exit
objstat $obj | { [ "$VER" ] && mar || stv; }

