#!/bin/bash
source ~/gen2/conf/bashrc
source gen2mkcmd
cmd=$PYTHONPATH/Gen2/client/g2cmd.py
arg=$(selcmd $*) || exit 1
exelog $cmd $arg
