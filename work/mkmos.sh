#!/bin/bash
csv2mdb -m mos mfp mma|mdb2xml > ~/ciax-xml/mdb-mos.xml
csv2mdb -m car mmc|mdb2xml > ~/ciax-xml/mdb-car.xml
