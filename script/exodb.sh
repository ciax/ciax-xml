#!/bin/bash
. ~/lib/libcsv.sh
devices=${1:-`ls ~/.var/status_???.json|cut -d_ -f2|cut -d. -f1`};shift
cmd=${1:-upd};shift
par="$*"
for id in $devices; do
    setfld $id || _usage_key
    echo "#### $obj($id) ####"
    output=$HOME/.var/status_$id.json
    VER=${VER:-exec} objcmd $obj $cmd $par
    [ $cmd = 'upd' ] &&
    <$output objstat $obj
done
