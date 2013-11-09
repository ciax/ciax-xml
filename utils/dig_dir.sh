#!/bin/bash
for i ; do
    [ -d "$i" ] || mkdir "$i"
    cd "$i"
done
