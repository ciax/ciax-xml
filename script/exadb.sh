#!/bin/bash
. ~/se/lib/libdb.sh cx_object
#objects=${1:-cf1 crt det dts cci mh1 mt3 mix map mma ml1};shift
objects=${1:-`cd ~/ciax-xml;ls adb-*.xml`};shift
cmd=${1:-upd};shift
par="$*"
for obj in $objects; do
    obj=${obj%.*}
    obj=${obj#*-}
    echo "#### $obj ####"
    dev=$(lookup $obj dev) || _usage_key
    file=$HOME/.var/status_$obj.mar
    VER=${VER:-exec} alicmd $obj $cmd $par
    [ $cmd = 'upd' ] &&
    alistat $obj $file| { [ "$VER" ] && mar || stv; }
done
