#!/bin/bash

[ "$1" ] || { echo "USAGE:agrep [attribute]"; exit; }
str=$1=[0-9A-Za-z\"*]+
egrep -h -o $str *.xml|sort -u
