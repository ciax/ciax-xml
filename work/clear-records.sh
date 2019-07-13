#!/bin/bash
# Clear records having 'busy'
# alias:clrec
cd ~/.var/record
for i in $(grep -l busy record_*.json);do
    rm $i
done
cd ~/.var/json
for i ; do
    [ -L "$i" -a ! -e "$i" ] || continue
    rm -f "$i"
    echo "[${i##*/}] is not linked"
done
librecarc -r
