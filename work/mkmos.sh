#!/bin/bash
cd ~/ciax-xml
csv2mdb -m mos mfp mma|mdb2xml > mdb-mos.xml
check-xml mdb-mos.xml
csv2mdb -m car mmc|mdb2xml > mdb-car.xml
check-xml mdb-car.xml
