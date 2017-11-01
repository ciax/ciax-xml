#!/bin/bash
#alias fsf
for f in $(egrep -o 'def _\w+' lib*|egrep -v '.+_$'|cut -d' ' -f2);do
    [ $(egrep -v '^ +def' lib* | grep $f|wc -l) = 1 ] || continue
    text-replace $f ${f}_
done
