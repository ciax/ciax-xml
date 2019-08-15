#!/bin/bash
source $HOME/bin/rc.bash.ciax-xml 
for i; do
    $HOME/bin/dvexe -e $i upd >/dev/null 2>&1
done
