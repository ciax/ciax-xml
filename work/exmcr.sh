#!/bin/bash
PROJ=dmcs
mos_sim -
sleep 5
dvexe -e tmc slot5
if [ "$1" = -l ] ; then
    VER=saved dvsv -e
    opt=l0
fi
mcrexe -en$opt upd
while
    mcrexe -en$opt cinit
    [ $? -gt 8 ]
do :;done
cd ~/ciax-xml
git status | grep nothing && git tag -f 'Success!mos-sim'$(date +%y%m%d)

