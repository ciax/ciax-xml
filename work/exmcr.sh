#!/bin/bash
PROJ=dmcs
mos_sim -
sleep 5
dvexe -e tmc slot10
mcrexe -en upd
mcrexe -en cinit
