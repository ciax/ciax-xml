#!/bin/bash
dig_dir(){
    for i ; do
        [ -d "$i" ] || mkdir "$i"
        cd "$i"
    done
}

dig_dir ~/.var cache
/bin/rm cache/*.mar >/dev/null 2>&1
cd ..
dig_dir json
/bin/rm *.json >/dev/null 2>&1
cd ~/ciax-xml
./utils/register-files.sh */
