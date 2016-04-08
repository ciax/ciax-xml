#!/usr/bin/env bash
#alias sim
sims="fpsim apsim carsim armsim bbsim"
killall $sims
if [ "$1" != '-d' ] ; then
    for i in $sims; do $i;done
fi
ps -ef|grep -v 'grep'|egrep "${sims// /|}"
