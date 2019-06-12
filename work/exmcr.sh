#!/bin/bash
PROJ=dmcs
mos_sim -
sleep 5
dvexe -e tmc slot5
case "$1" in
    -l)
        # VER=event:saved
        dvsv -e
        # export VER=event:loaded
        opt=l0
        ;;
    -p)
        dvsv -p
        opt=p
        ;;
esac
mcrexe -en$opt upd
while
    mcrexe -en$opt cinit
    [ $? -gt 8 ]
do :;done
[ "$opt" ] && dvsv
mos_sim
cd ~/ciax-xml
git status | grep nothing && git tag -f 'Success!mos-sim'$(date +%y%m%d)
