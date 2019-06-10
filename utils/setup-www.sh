#!/bin/bash
# Required packages: php-all-dev yui-compressor
# Required packages(Debian,Ubuntu,Raspbian):apache2 php-elisp
# Required packages(Debian,Ubuntu): libapache2-mod-php5 php5-sqlite
# Required packages(Raspbian):libapache2-mod-php php-sqlite3
# Required packages(CentOs):httpd php php-pear php-pdo perl-XML-XPath php5-sqlite
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
