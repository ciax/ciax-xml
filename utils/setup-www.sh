#!/bin/bash
# Required packages: php5-sqlite
dir=$HOME/.var/json
for i in $dir/*; do
    [ -L "$i" -a ! -e "$i" ] && rm "$i"
done
ln -sf $HOME/ciax-xml/web*/*  $dir/
sudo ln -sf ~/ciax-xml /var/www/html
sudo ln -sf ~/.var/json /var/www/html
sudo ln -sf ~/.var/log /var/www/html
sudo ln -sf $(pwd -P)/*.js $dir
