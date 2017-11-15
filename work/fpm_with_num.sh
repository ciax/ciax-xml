#!/bin/bash
shopt -s extglob
while read m f; do
    echo -en "$m\t$f\t"
    base=${f#lib}
    echo "$(egrep -v '^ *def' $f|egrep $m|wc -l)/$(egrep $m lib!($base) | wc -l)"
done < <(find_priv_methods -d lib*|sort)
