#!/bin/bash
clog=$HOME/.var/log/cron.log
[ "$1" ] || { cat $clog; exit; }
[ -s $clog -o -t 0 ] || env > $clog  
HOSTNAME=$(hostname)
source $HOME/bin/rc.bash.ciax-xml 
date >> $clog
for i; do
    $HOME/bin/dvexe -e $i upd >> $clog 2>&1
done
