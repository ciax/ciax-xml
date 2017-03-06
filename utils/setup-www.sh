#!/bin/bash
# Required packages: make php5-sqlite yui-compressor
dir=$HOME/.var/json
for i in $dir/*; do
    [ -L "$i" -a ! -e "$i" ] && rm "$i"
done
ln -sf $HOME/ciax-xml/web*/*  $dir/
sudo ln -sf ~/ciax-xml /var/www/html
for i in json log record; do
    sudo ln -sf ~/.var/$i /var/www/html
done
sudo ln -sf $(pwd -P)/*.js $dir
# install jslib
[ -d ~/jslib ] || mkdir ~/jslib
cd ~/jslib
if [ ! -d flot ] ; then
    git clone http://github.com/flot/flot.git
    cd flot
    make
    sudo ln -sf $(pwd -P)/*.js $dir
fi
