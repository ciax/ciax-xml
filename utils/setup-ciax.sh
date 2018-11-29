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
        mkdir -p "$i"
        cd "$i"
    done
}
init_bashrc(){
    grep -q '#initrc' ~/.profile >/dev/null 2>&1 && return
    echo $C3"Update .profile"$C0
    echo 'shopt -s nullglob;for i in ~/bin/rc.login*;do . $i;done #initrc' >> ~/.profile
}
echo $C3"Prepare work dirs"$C0
dig_dir ~/.var
mkdir -p cache json log record
/bin/rm cache/*.mar >/dev/null 2>&1
/bin/rm *.json >/dev/null 2>&1
dig_dir ~/bin
echo $C3"Make script symlinks"$C0
mklink ~/ciax-xml/*
init_bashrc
