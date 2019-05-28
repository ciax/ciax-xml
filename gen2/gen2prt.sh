#!/bin/bash
source ~/gen2/conf/bashrc
source gen2mkprt
prt=$PYTHONPATH/SOSS/status/screenPrint.py
[ "$1" ] || usage
# Parameter: all, iid ... -> Visible mode
# parameter: CXWS.OSS ... -> Raw mode
arg=$(selprt $*) && set - $arg || opt='-R'
$prt $opt $*
