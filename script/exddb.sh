#!/bin/bash
dev=${1:-k3n} cmd=${2:-getstat}
par=$3
input="$HOME/.var/${dev}_stat_getstat.bin"
{
devcmd $dev $cmd $par || exit
devstat $dev getstat < $input | mar
} | visi

