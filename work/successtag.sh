#!/bin/bash
# Add git tag for the version of successful operation
# You can Specify date
date=$(date ${1:+-d $1} +%Y/%m/%d)
tag="Success!${PROJ^^}@$HOSTNAME($date)"
git check-ref-format "$tag" || exit
echo "$tag"
git tag $tag
git push --tag
