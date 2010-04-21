#!/bin/bash
read i
echo "`echo -n "$i"|visi` =>" >&2
file=~/.var/$1_$2.bin
[ -e "$file" ] || exit
(echo -n "=> ";cat "$file"|visi) >&2
cat "$file" 
