#!/bin/bash
src=$HOME/ciax-xml/webapp
dir=$HOME/.var/json
for i in $dir/*; do
    [ -L "$i" -a ! -e "$i" ] && rm "$i"
done
ln -sf $src/*  $dir/
sudo ln -sf ~/ciax-xml /var/www/html
sudo ln -sf ~/.var/json /var/www/html
sudo ln -sf ~/.var/log /var/www/html
