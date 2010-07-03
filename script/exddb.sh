#!/bin/bash
var="$HOME/.var"
dev="${1:-mel srm k3n bbe tpg}"
cmd="${2:-getstat}"
for d in $dev; do
    input="$var/device_${d}_2010.log"
    echo "#[$d]#"
    devcmd $d $cmd || exit 1
    echo
    grep "rcv:$cmd" $input|tail -1| devstat $d $cmd|mar
done  | visi
