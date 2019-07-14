#!/bin/bash
# Add git tag for the version of successful operation
# You can Specify date
chktag(){
    echo "$*"
    git check-ref-format "$*" || { echo "Invalid format"; return 1; }
}
settag(){
    if [ "$s" ] ; then
        git tag "$*"
        git push --tag
    else
        echo "Usage: successtag (-s: real setting, -d: specific date) (message)"
    fi
}
[ "$1" = -s ] && { s=1; shift; }
[ "$1" = -d ] && { shift; sd="-d ${1:-now}"; shift; }
date=$(date $sd +%Y/%m/%d)
br=$(git branch --contains)
IFS=_
tag="$date-Success@$HOSTNAME(project=$PROJ,branch=${br#* })$*"
chktag $tag || exit 1
settag $tag
