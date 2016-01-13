#!/bin/bash
# Required packages: wget
# Desctiption: get moircs db from gdocs and split into db-files
. func.getpar
_temp dlfile dbfile
# Set var
dldir=~/.var/download
site="https://docs.google.com/spreadsheets/d/"
key="1zeyvDQuaoTdHhBrJcI011tNdiq-br_RlU2ts0-mUlmQ"
gid=1403278820 # Filter Table
sheet="moircs-filter"
tsvfile=$dldir/$sheet.tsv
url="$site$key/export?format=tsv&id=$key&gid=$gid"
# Download
_warn "Retrieving $sheet($url)"
wget -q --progress=dot -O $dlfile "$url" || exit
nkf -d --in-place $dlfile
[ -d $dldir ] || mkdir -p $dldir
cp $dlfile $tsvfile
