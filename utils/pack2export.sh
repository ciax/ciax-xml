#!/bin/bash
clrdir(){
    [ -e "$1" ] && /bin/rm -r $1
    mkdir "$1"
}

pfx=~/package/ciax-xml

mkcp(){
    dst=$1;shift
    clrdir $pfx/$dst
    cd ~/ciax-xml/$dst || { echo "NO ~/ciax-xml/$dst dir"; exit; }
    for i ;do
        cp $i $pfx/$dst
    done
}


clrdir ~/package

mkcp "" '*.xml'
mkcp script '*.rb'
cp readme_exp.txt $pfx/script/readme.txt

mkcp schema '*'
mkcp webapp '*'
mkcp utils chkxml.sh frmsimsql.rb mkhtml.sh sqlog.rb inst.sh

cmt=$(git log -1 --abbrev=4 --abbrev-commit|grep commit)

cd ~/package
pkg=ciax-xml-${cmt#* }.tgz
tar cvzf $pkg ciax-xml
cp $pkg /var/www/dav