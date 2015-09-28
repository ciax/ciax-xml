#!/bin/bash
src=$HOME/ciax-xml/webapp
dir=$HOME/.var/json
ln -sf $src/*  $dir/
sudo ln -sf ~/ciax-xml /var/www/html
sudo ln -sf ~/.var/json /var/www/html
