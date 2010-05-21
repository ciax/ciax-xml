#!/bin/bash
for dev in ${1:-mel srm k3n bbe}; do
    input="$HOME/.var/${dev}_rcv_getstat.bin"
    echo "#[$dev]#"
    {
	devcmd $dev getstat || exit
	devstat $dev getstat < $input | mar
    } | visi
done
