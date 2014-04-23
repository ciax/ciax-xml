#!/bin/bash
init_bashrc(){
    grep -q '#initrc' ~/.bashrc >/dev/null 2>&1 && return
    echo 'shopt -s nullglob;for i in ~/bin/rc.*;do . $i;done #initrc' >> ~/.bashrc
}
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
init_pkg(){
    read dist dmy < /etc/issue
    case "$dist" in
        Debian)
            sudo apt-get install ruby-libxml socat sqlite3
            ;;
        Ubuntu)
            sudo apt-get install ruby-libxml socat sqlite3
            ;;
        CentOS)
            ;;
        *);;
    esac
}
dig_dir ~/.var cache
/bin/rm cache/*.mar >/dev/null 2>&1
dig_dir ~/.var/json
/bin/rm *.json >/dev/null 2>&1
dig_dir ~/bin
mklink ~/ciax-xml/*
init_bashrc
init_pkg
