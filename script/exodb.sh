#!/bin/bash
. ~/se/lib/libdb.sh cx_object
for obj in crt det cf1 cci; do
    dev=$(lookup $obj dev) || _usage_key
    objcmd $obj upd
    objstat $obj | { [ "$VER" ] && mar || stv; }
done


