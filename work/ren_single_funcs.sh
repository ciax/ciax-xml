#!/bin/bash
#alias fsf
for f in $(egrep -o 'def __\w+_' lib*|egrep -v '___.+\b'|cut -d' ' -f2);do
    [ $(grep $f lib*|wc -l) = 2 ] || continue
    text-replace $f _${f%_}
done
