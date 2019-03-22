#!/bin/bash
source ~/gen2/conf/bashrc
source gen2mkcmd
cmd=$PYTHONPATH/Gen2/client/g2cmd.py
arg=$(selcmd $*) || exit 1
[ "${arg##* }" -gt 10 ] && opt=-b
# Long term command should be done backgroup to update status
exelog $opt $cmd $arg
