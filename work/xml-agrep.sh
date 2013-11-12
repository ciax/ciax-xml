#!/bin/bash
# XML Attribute Grep
[ "$1" ] || { echo "USAGE:xml_agrep [attribute]"; exit; }
str=" $1=[\"\'][[:graph:]]+[\"\']"
egrep -h -o "$str" *.xml|sort -u
