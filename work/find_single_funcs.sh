#!/bin/bash
#alias fsf
for f in $(egrep -o 'def _\w+_' lib*|cut -d' ' -f2);do
    grep $f lib*
done
