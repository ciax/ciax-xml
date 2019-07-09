#!/bin/bash
PROJ=dmcs
mos_sim -
sleep 5
dvexe -e tmc slot5
case "$1" in
    -l)
        # VER=event:saved
        dvsv -eb
        # export VER=event:loaded
        opt=lwhlocalhost
        ;;
    -p)
        dvsv -pb
        opt=p
        ;;
    -c)
        mcrsv -pnb
        opt=c
        ;;
    *)
        opt=e
        ;;
esac
mcrexe -n$opt upd
while
    mcrexe -n$opt cinit
    [ $? -gt 8 ]
do :;done
[ "$opt" ] && dvsv
mos_sim
cd ~/ciax-xml
git status | grep nothing && git tag -f 'Success!mos-sim'$(date +%y%m%d)
