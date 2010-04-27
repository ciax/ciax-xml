#!/bin/bash
dev=${1:-k3n} cmd=${2:-getstat}
par=$3
input="$HOME/.var/${dev}_getstat.bin"
cmdfrm="$HOME/.var/${dev}_$cmd.cmd"
devcmd $dev $cmd $par > $cmdfrm|| exit
visi $cmdfrm
devstat $dev getstat < $input | mar

