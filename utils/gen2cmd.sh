#!/bin/bash
source ~/gen2/conf/bashrc
source gen2mkcmd
# Long term command should be done backgroup to update status
gen2exe $PYTHONPATH/Gen2/client/g2cmd.py $(selcmd $*)
