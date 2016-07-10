#!/bin/bash
# Required packages: php5-sqlite yui-compressor
jslink(){
    for i in *.js; do
        sudo ln -sf $(pwd -P)/$i $dir
    done
}
dir=$HOME/.var/json
for i in $dir/*; do
    [ -L "$i" -a ! -e "$i" ] && rm "$i"
done
ln -sf $HOME/ciax-xml/web*/*  $dir/
sudo ln -sf ~/ciax-xml /var/www/html
for i in json log record; do
    sudo ln -sf ~/.var/$i /var/www/html
done
jslink
# install jslib
[ -d ~/jslib ] || mkdir ~/jslib
cd ~/jslib
if [ ! -d flot ] ; then
    git clone http://github.com/flot/flot.git
    cd flot
    make
    jslink
fi
