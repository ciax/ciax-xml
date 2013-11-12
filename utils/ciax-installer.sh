#!/bin/bash
# bin dir separated for executable link in hg repos
# "Usage: ${0##*/} [DIR..] | [SRC..]"
dig_dir(){
    for i ; do
        [ -d "$i" ] || mkdir "$i"
        cd "$i"
    done
}
cd ~/ciax-xml
for i in */ ; do
    ./utils/register_files.sh $i
done

dig_dir ~/.var
dig_dir cache
cd ..
dig_dir json

register_bashrc
