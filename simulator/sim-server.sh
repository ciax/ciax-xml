#!/usr/bin/env bash
sims="fpsim apsim carsim armsim bbsim"
killall $sims
if [ "$1" == '-d' ] ; then
    dvsv > /dev/null 2>&1
    mcrsv > /dev/null 2>&1
else
    for i in $sims; do $i;done
    dvsv -e tfp tap tmc tma tb2
    mcrsv -c test
fi
