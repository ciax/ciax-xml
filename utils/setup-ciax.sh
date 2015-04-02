#!/bin/bash
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
    grep -q '#initrc' ~/.bashrc >/dev/null 2>&1 && return
    echo $C3"Update .bashrc"$C0
    echo 'shopt -s nullglob;for i in ~/bin/rc.*;do . $i;done #initrc' >> ~/.bashrc
}
init_pkg(){
    echo $C3"Install required packages"$C0
    read dist dmy < /etc/issue
    case "$dist" in
        *bian)
            sudo apt-get install ruby-libxml socat sqlite3 apache2 libxml2-utils
            ;;
        Ubuntu)
            sudo apt-get install ruby-libxml socat sqlite3 apache2
            ;;
        CentOS)
            ;;
        *);;
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
sudo ln -s ~/.var/json /var/www/
