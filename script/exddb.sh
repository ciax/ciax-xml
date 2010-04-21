#!/bin/bash
dev=${1:-k3n} cmd=${2:-getstat}
par=$3
input="$HOME/.var/${dev}_getstat.bin"
cmdfrm="$HOME/.var/${dev}_$cmd.cmd"
output="$HOME/.var/${dev}.mar"
devctrl $dev $cmd $par > $cmdfrm|| exit
visi $cmdfrm
devstat $dev getstat < $input > $output || exit
mar $output
