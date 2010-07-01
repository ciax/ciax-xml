#!/bin/bash
var="$HOME/.var"
for dev in ${1:-mel srm k3n bbe tpg}; do
    input="$var/device_${dev}_2010.log"
    echo "#[$dev]#"
    devcmd $dev getstat || exit 1
    echo
    tail -1 $input| devstat $dev getstat|mar
done  | visi
