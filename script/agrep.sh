#!/bin/bash
[ "$1" ] || { echo "USAGE:agrep [attribute]"; exit; }
str=$1=[\"\'][[:graph:]]+[\"\']
egrep -h -o $str *.xml|sort -u
