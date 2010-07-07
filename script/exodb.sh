#!/bin/bash
. ~/se/lib/libdb.sh cx_object
for obj in ${1:-crt det cf1 cci}; do
    dev=$(lookup $obj dev) || _usage_key
    file=$HOME/.var/field_$obj.mar
    VER=${VER:-exec} objcmd $obj upd < $file
    objstat $obj $file| { [ "$VER" ] && mar || stv; }
done


