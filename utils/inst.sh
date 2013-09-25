#!/bin/bash
clrdir(){
    [ -d "$1" ] || mkdir "$1"
}

cd ~/ciax-xml
for i in */ ; do
    utils/init-bin.sh $i
done

clrdir ~/.var
cd ~/.var
clrdir cache
clrdir json
