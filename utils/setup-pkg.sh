#!/bin/bash
# Required packages(Debian,Raspbian,Ubuntu): make gcc socat sqlite3 ruby ruby-all-dev ruby-libxml libxml2-utils apache2 libapache2-mod-php php-sqlite3 php-elisp socat libxml-xpath-perl
# Required packages(CentOs): make gcc ruby-devel libxml2-devel httpd socat sqlite httpd php php-pear perl-XML-XPath
# Required modules(Ruby): json libxml-ruby
echo $C3"Install required packages"$C0
if [ -f /etc/centos-release ]; then
    dist=CentOs
else
    read dist dmy < /etc/issue
fi
pkgs=$(grep "Required packages(*.$dist" $0|cut -d: -f2)
case "$dist" in
    *bian|Ubuntu)
        sudo apt-get install $pkgs
        ;;
    CentOs)
        sudo yum install $pkgs
        sudo gem install json libxml-ruby
        ;;
    *)   
        ;;
esac
# Install gem apps
sudo gem install ox rubocop
