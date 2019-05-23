#!/bin/bash
source ~/gen2/conf/bashrc
source gen2mkcmd
cmd=$PYTHONPATH/Gen2/client/g2cmd.py
set - "$(selcmd $*)" || exit 1
[ "$2" ] && [ "$2" -gt 10 ] && opt=-b
# Long term command should be done backgroup to update status
gen2exe $opt $cmd $*
