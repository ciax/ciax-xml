#!/bin/bash
# Required packages: make gcc socat
# Required packages(CentOs): sqlite ruby-devel libxml2-devel perl-XML-XPath
# Required packages(Debian,Raspbian,Ubuntu): sqlite3 ruby-all-dev ruby-libxml libxml2-utils libxml-xpath-perl
# Required modules(Ruby): json libxml-ruby
echo $C3"Install required packages"$C0
if [ -f /etc/centos-release ]; then
    dist=CentOs
else
    read dist dmy < /etc/issue
fi
here=$(dirname $0)
pkgs=$(grep "Required packages(*.$dist" $here/*|cut -d: -f3)
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
