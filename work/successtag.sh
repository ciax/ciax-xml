#!/bin/bash
# Add git tag for the version of successful operation
# You can Specify date
[ "$1" = -s ] && { s=1; shift; }
date=$(date ${1:+-d $1} +%Y/%m/%d)
br=$(git branch --contains)
tag="Success!${PROJ^^}@$HOSTNAME($date)-${br#* }"
git check-ref-format "$tag" || { echo "Invalid format"; exit 1; }
echo "$tag"
[ "$s" ] || { echo "successtag (-s: real setting)"; exit; }
git tag $tag
git push --tag
