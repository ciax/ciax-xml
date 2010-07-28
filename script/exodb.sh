#!/bin/bash
. ~/se/lib/libdb.sh cx_object
for obj in ${1:-cf1 crt det dts cci mh1 mt3 mix map mma ml1}; do
    echo "#### $obj ####"
    dev=$(lookup $obj dev) || _usage_key
    file=$HOME/.var/field_$obj.mar
    VER=${VER:-exec} objcmd $obj ${2:-upd} < $file
    objstat $obj $file| { [ "$VER" ] && mar || stv; }
done
