#!/bin/bash
# Required packages: make php5-sqlite yui-compressor php-pdo
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
