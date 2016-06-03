#!/bin/bash
#alias mkmos
cd ~/ciax-xml
csv2mdb -m mos mfp mma|mdb2xml > mdb-mos.xml
csv2mdb -m car mmc|mdb2xml > mdb-car.xml
for i in mfp mma mmc map; do
    opt="$opt -e s/\([\"_]\)$i\([\"_]\)/\1t${i#*m}\2/g"
done
sed $opt -e 's/"mos"/"tmos"/' mdb-mos.xml > mdb-tmos.xml
sed $opt -e 's/"car"/"tcar"/' mdb-car.xml > mdb-tcar.xml
check-xml mdb-car.xml mdb-mos.xml mdb-tmos.xml mdb-tcar.xml

