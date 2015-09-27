#!/bin/bash
# Required packages(Debian,Raspbian,Ubuntu): ruby ruby-libxml libxml2-utils apache2 socat libxml-xpath-perl
# Required packages(CentOs): ruby-devel libxml2-devel httpd socat
# Required modules(Ruby): json libxml-ruby
mklink(){
    for i;do
        [ -d "$i" ] && (dig_dir "$i";mklink *)
        base=${i##*/}
        core=${base%.*}
        dir="$(pwd -P)"
        case $i in
            *.rb|*.sh) ln -sf "$dir/$base" ~/bin/$core;;
            *);;
        esac
    done
}
dig_dir(){
    for i ; do
        [ -d "$i" ] || mkdir "$i"
        cd "$i"
    done
}
init_bashrc(){
    grep -q '#initrc' ~/.profile >/dev/null 2>&1 && return
    echo $C3"Update .profile"$C0
    echo 'shopt -s nullglob;for i in ~/bin/rc.login*;do . $i;done #initrc' >> ~/.profile
}
init_pkg(){
    echo $C3"Install required packages"$C0
    if [ -f /etc/centos-release ]; then
        dist=CentOS
    else
        read dist dmy < /etc/issue
    fi
    case "$dist" in
        *bian|Ubuntu)
            sudo apt-get install socat sqlite3 ruby-libxml libxml2-utils libapache2-mod-php5
            ;;
        CentOS)
            sudo yum install socat sqlite ruby-devel httpd php php-pear libxml2-devel perl-XML-XPath
            sudo gem install json libxml-ruby
            ;;
        *)
            return
            ;;
    esac
}
echo $C3"Prepare work dirs"$C0
dig_dir ~/.var cache
/bin/rm cache/*.mar >/dev/null 2>&1
dig_dir ~/.var/json
/bin/rm *.json >/dev/null 2>&1
dig_dir ~/bin
echo $C3"Make script symlinks"$C0
mklink ~/ciax-xml/*
init_bashrc
init_pkg
setup-www
