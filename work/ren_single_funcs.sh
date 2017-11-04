#!/bin/bash
#alias rsf
#for f in $(egrep -o 'def _[0-9a-z]\w+\b' lib*|cut -d' ' -f2);do
while read def method; do
    ln=$(egrep -o "$method\b" lib*|wc -l)
    [ $ln -eq 2 ] || continue
    echo $method
done < <(grep -A100 private lib*|grep -v ___| egrep -o ' def \w+\b'|sort -u)
