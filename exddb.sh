#!/bin/bash
dev=${1:-k3n} cmd=${2:-getstat}
ext=${3:-bin}
input="$HOME/.var/${dev}_getstat.${ext}"
output="$HOME/.var/${dev}.mar"
devctrl $dev $cmd < $output|visi && 
devstat $dev getstat < $input > $output &&
mar $output
