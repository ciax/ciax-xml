#!/bin/bash
cd ../..
export HOME=$PWD
export RUBYLIB=$HOME/ciax-xml/script
bin/dvexe $1 $2 2>&1
