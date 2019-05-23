#!/bin/bash
source ~/gen2/conf/bashrc
source gen2mkcmd
par=$(selcmd $*) || exit 1
set - $par
[ "$2" ] && [ ${par##* } -gt 10 ] && opt=-b
# Long term command should be done backgroup to update status
gen2exe $opt $par
