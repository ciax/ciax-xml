#!/bin/bash
cd ../..
export HOME=$PWD
export XMLPATH=$HOME/ciax-xml
export RUBYLIB=$XMLPATH/script
bin/dvexe $1 $2 2>&1
