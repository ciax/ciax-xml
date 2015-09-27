#!/bin/bash
src=$HOME/ciax-xml/webapp
dir=$HOME/.var/json
ln -svf $src/*  $dir/
sudo ln -sf ~/.var/json /var/www/html
