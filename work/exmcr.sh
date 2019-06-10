#!/bin/bash
PROJ=dmcs
mos_sim -
sleep 5
dvexe -e tmc slot5
mcrexe -en upd
while
    mcrexe -en cinit
    [ $? -gt 8 ]
do :;done
cd ~/ciax-xml
git status | grep nothing && git tag -f 'Success!mos-sim'$(date +%y%m%d)

