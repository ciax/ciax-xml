#!/usr/bin/env bash
#alias sim
sims="fpsim apsim carsim armsim bbsim"
killall $sims
if [ "$1" == '-d' ] ; then
    dvsv > /dev/null 2>&1
else
    for i in $sims; do $i;done
    dvsv -e tfp tap tmc tma tb2
fi
