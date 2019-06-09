#!/bin/bash
# Required packages: php-all-dev php5-sqlite yui-compressor
# Required packages(Debian,Raspbian,Ubuntu):apache2 libapache2-mod-php5 php-elisp
# Required packages(CentOs):httpd php php-pear php-pdo perl-XML-XPath
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
