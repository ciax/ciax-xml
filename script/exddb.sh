#!/bin/bash
var="$HOME/.var"
for dev in ${1:-mel srm k3n bbe}; do
    input="$var/${dev}_rcv1_getstat.bin"
#    rm "$var/$dev.mar"
    echo "#[$dev]#"
    devcmd $dev getstat|visi
    devstat $dev getstat< $input|mar
done
