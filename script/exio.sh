#!/bin/bash
read i
echo "`echo -n "$i"|visi` =>" >&2
file=~/.var/$1_getstat.bin
[ -e "$file" ] || exit
(echo -n "=> ";cat "$file"|visi) >&2
cat "$file" 
