#!/bin/bash
files=${*:-*.rb}
for file in $files; do
    ./$file
    [ $? = 1 ] && break
done
