#!/bin/bash
#alias fsf
for f in $(egrep -o 'def _\w+_' lib*|cut -d' ' -f2);do
    grep $f lib*
    #    [ $(egrep -v '^ +def' lib* | grep $f|wc -l) = 1 ] || continue
#    echo $f
done
