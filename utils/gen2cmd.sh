#!/bin/bash
source ~/gen2/conf/bashrc
cmd=$PYTHONPATH/Gen2/client/g2cmd.py
arg=$(gen2mkcmd $*) || exit 1
exelog $cmd $arg
