#!/bin/bash
mklink(){
    for i;do
        [ -d "$i" ] && (dig_dir "$i";mklink *)
        r="$(pwd -P)/${i##*/}"
        case $i in
            *.rb|*.sh) ln -sf "$r" ~/bin/;;
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

dig_dir ~/.var cache
/bin/rm cache/*.mar >/dev/null 2>&1
dig_dir ~/.var/json
/bin/rm *.json >/dev/null 2>&1
mklink ~/ciax-xml/*
