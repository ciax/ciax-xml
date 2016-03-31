#!/usr/bin/env bash
sims="fpsim apsim carsim armsim bbsim"
killall $sims
for i in $sims; do $i;done
dvsv -e tfp tap tmc tma tb2
mcrsv -c test
