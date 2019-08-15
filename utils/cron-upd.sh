#!/bin/bash
source $HOME/bin/rc.bash.ciax-xml 
clog=$HOME/.var/log/cron.log
date >> $clog
for i; do
    $HOME/bin/dvexe -e $i upd >> $clog 2>&1
done
