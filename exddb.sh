#!/bin/bash
dev=${1:-k3n} cmd=${2:-getstat}
ext=${3:-bin}
input="$HOME/.var/${dev}_getstat.${ext}"
output="$HOME/.var/${dev}.mar"
devcmd $dev $cmd < $output|visi && 
devstat $dev getstat < $input > $output &&
mar $output
