#!/bin/bash
#alias fsf
for f in $(egrep -o 'def _[0-9a-z]\w+_\b' lib*|cut -d' ' -f2);do
    [ $(grep "def $f" lib*|wc -l) > 1 ] || continue
    #    text-replace
echo $f
    #    echo _${f%_}
done
