#!/usr/bin/env bash
fpsim &
carsim &
armsim &
bbsim &
dvsv -e tfp tmc tma tb2
