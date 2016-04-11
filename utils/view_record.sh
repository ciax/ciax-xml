#!/bin/bash
# Record viewer
#alias vr
if [ "$1" ] ; then
    file=$(grep -l "cid.:.*$1" $(find ~/.var/json/record* -size +1k)|tail -1)
else
    file=~/.var/json/record_latest.json
fi
librecord < $file
