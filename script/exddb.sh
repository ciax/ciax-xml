#!/bin/bash
dev=${1:-k3n} cmd=${2:-getstat}
ext=${3:-bin}
input="$HOME/.var/${dev}_getstat.${ext}"
cmdfrm="$HOME/.var/${dev}_$cmd.cmd"
output="$HOME/.var/${dev}.mar"
devctrl $dev $cmd < $output > $cmdfrm|| exit
visi $cmdfrm
devstat $dev getstat < $input > $output || exit
mar $output
