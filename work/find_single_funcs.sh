#!/bin/bash
#alias fsf
for f in $(egrep -o 'def \w+' lib*|cut -d' ' -f2);do
    [ $(grep -o $f lib*|wc -l) -eq 1 ] && echo $f
done
