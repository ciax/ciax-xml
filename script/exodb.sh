#!/bin/bash
. ~/se/lib/libdb.sh cx_object
for obj in ${1:-crt det cf1 cci}; do
    dev=$(lookup $obj dev) || _usage_key
    VER=${VER:-exec} objcmd $obj upd
    objstat $obj | { [ "$VER" ] && mar || stv; }
done


