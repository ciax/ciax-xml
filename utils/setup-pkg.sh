#!/bin/bash
# Required packages(Debian,Raspbian,Ubuntu): ruby ruby-libxml libxml2-utils apache2 socat libxml-xpath-perl php5-sqlite
# Required packages(CentOs): ruby-devel libxml2-devel httpd socat
# Required modules(Ruby): json libxml-ruby
echo $C3"Install required packages"$C0
if [ -f /etc/centos-release ]; then
    dist=CentOS
else
    read dist dmy < /etc/issue
fi
case "$dist" in
    *bian|Ubuntu)
        sudo apt-get install socat sqlite3 ruby-libxml libxml2-utils libapache2-mod-php php-sqlite3 php-elisp
        ;;
    CentOS)
        sudo yum install socat sqlite ruby-devel httpd php php-pear libxml2-devel perl-XML-XPath
        sudo gem install json libxml-ruby
        ;;
    *)
        return
        ;;
esac
# Install gem apps
sudo gem install rubocop
