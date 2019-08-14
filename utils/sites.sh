#!/bin/bash
# usage: sites (command)
list(){
    grep site ~/ciax-xml/idb*|egrep -o 'id="\w*"'|cut -d\" -f2|sort -u
}
if [ "$1" ]; then
    list | xargs -L 1 $*
else
    list
fi
