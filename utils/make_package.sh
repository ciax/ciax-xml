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

mkcp "" '*.xml'
cmt=$(git log -1 --abbrev=4 --abbrev-commit|grep commit)
mkcp schema '*'
mkcp webapp '*'
mkcp utils '*'
mkcp script '*.rb'
cp readme_exp.txt $pfx/script/readme.txt
echo " $cmt" >> $pfx/script/readme.txt

cd ~/package
pkg=ciax-xml-$(date +%y%m%d).tgz
tar cvzf $pkg ciax-xml
cp $pkg /var/www/dav