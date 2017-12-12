#!/bin/bash
#alias mkcx
cd ~/ciax-xml
csv2mdb -m cx15 crt dso dsi dts|mdb2xml > mdb-cx15.xml
check-xml mdb-cx15.xml

