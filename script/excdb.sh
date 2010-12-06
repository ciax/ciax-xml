#!/bin/bash
. ~/lib/libcsv.sh
devices=${1:-`ls ~/.var/field_???.json|cut -d_ -f2|cut -d. -f1`};shift
cmd=${1:-upd};shift
par="$*"
for id in $devices; do
    setfld $id || _usage_key
    echo "#### $cls($id) ####"
    file=$HOME/.var/field_$id.json
    VER=${VER:-exec(cdb)} clscmd $cls $cmd $par < $file
    [ $cmd = 'upd' ] || continue
    echo " *** Status ***"
    clsstat $cls < $file | clsview
    echo
done
