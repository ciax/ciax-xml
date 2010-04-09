#!/bin/bash
dev=${1:-k3n} cmd=${2:-getstat}
input="$HOME/.var/${dev}_${cmd}.bin"
output="$HOME/.var/${dev}.mar"
devcmd $dev $cmd|visi && 
devstat $dev $cmd < $input > $output &&
mar $output


