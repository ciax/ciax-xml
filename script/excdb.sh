#!/bin/bash
. ~/lib/libcsv.sh
objects=${1:-cf1 crt det dts cci mh1 mt3 mix map mma ml1};shift
cmd=${1:-upd};shift
par="$*"
for obj in $objects; do
    export obj
    echo "#### $obj ####"
    dev=$(lookup $obj dev) || _usage_key
    file=$HOME/.var/field_$obj.mar
    VER=${VER:-exec} clscmd $dev $cmd $par < $file
    [ $cmd = 'upd' ] && clsstat $dev $obj < $file| mar
done
