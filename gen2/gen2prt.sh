#!/bin/bash
source gen2env
source gen2mkprt
[ "$1" ] || usage
# Parameter: all, iid ... -> Visible mode
# parameter: CXWS.OSS ... -> Raw mode
arg=$(selprt $*) && set - $arg || opt='-R'
${g2prt:-g2prt} $opt $*
