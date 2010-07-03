#!/bin/bash
var="$HOME/.var"
cmd="getstat"
for dev in ${1:-mel srm k3n bbe tpg}; do
    input="$var/device_${dev}_2010.log"
    echo "#[$dev]#"
    devcmd $dev $cmd || exit 1
    echo
    grep "rcv:$cmd" $input|tail -1| devstat $dev getstat|mar
done  | visi
