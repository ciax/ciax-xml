#!/bin/bash
#alias fpm
# Output: Method File #self #others
# Numbers: in def/use
ARGV="$*"
shopt -s extglob
while read method file; do
    mdef=0
    muse=0
    odef=0
    ouse=0
    while read line; do
        if [[ $line =~ $file ]]; then
            [[ $line =~ def ]] && mdef=$(( mdef + 1 )) || muse=$(( muse + 1 ))
        else
            [[ $line =~ def ]] && odef=$(( odef + 1 )) || ouse=$(( ouse + 1 ))
        fi        
    done < <(grep -w $method $ARGV)
    echo -e "$method\t$file\t$mdef/$muse $muse/$ouse"
done < <(find_priv_methods -d $ARGV)|expand -t 20|sort
echo -e "Method\tFile\tdef/use(self) def/use(others)"|expand -t 20
