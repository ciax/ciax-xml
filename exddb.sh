#!/bin/bash
dev=${1:-k3n} cmd=${2:-getstat}
ext=${3:-bin}
input="$HOME/.var/${dev}_${cmd}.${ext}"
output="$HOME/.var/${dev}.mar"
devcmd $dev $cmd|visi && 
devstat $dev $cmd < $input > $output &&
mar $output
