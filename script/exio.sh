#!/bin/bash
read i
file=~/.var/$1_$2.bin
[ -e "$file" ] && cat "$file"
