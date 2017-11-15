#!/bin/bash
#alias fpm
# Output: Method File numbers
# Numbers: used in self/others
ARGV="$*"
shopt -s extglob
while read method file; do
    a=0
    b=0
    while read line; do
        if [[ $line =~ $file ]]; then
            a=$(( a + 1 ))
        else
            b=$(( b + 1 ))
        fi        
    done < <(egrep -v '^ *def' $ARGV|egrep $method\\b)
    echo -e "$method\t$file\t$a/$b"
done < <(find_priv_methods -d $ARGV)|expand -t 20|sort
echo -e "Method\tFile\tself/others"|expand -t 20
