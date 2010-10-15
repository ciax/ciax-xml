#!/bin/bash
. ~/lib/libcsv.sh
#objects=${1:-cf1 crt det dts cci mh1 mt3 mix map mma ml1};shift
objects=${1:-`cd ~/ciax-xml;ls odb-*.xml`};shift
cmd=${1:-upd};shift
par="$*"
for obj in $objects; do
    obj=${obj%.*}
    obj=${obj#*-}
    echo "#### $obj ####"
    dev=$(lookup $obj dev) || _usage_key
    input=$HOME/.var/field_$obj.mar
    output=$HOME/.var/status_$obj.mar
    VER=${VER:-exec} objcmd $obj $cmd $par < $input
    [ $cmd = 'upd' ] &&
    objstat $output| { [ "$VER" ] && mar || stv; }
done
