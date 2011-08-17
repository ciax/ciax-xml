#!/bin/bash
. ~/lib/libcsv.sh
set
for i in $HOME/.var/json/status_*.json; do

    _msg `basename $i`
    watches < $i
done
