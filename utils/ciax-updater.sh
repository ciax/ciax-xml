#!/bin/bash
cd
[ -e ciax-xml.tgz ] && rm ciax-xml.tgz
wget http://ciax.sum.naoj.org/dav/ciax-xml.tgz
tar xvzf ciax-xml.tgz
clean_up
