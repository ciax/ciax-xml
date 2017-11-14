while read m f; do
    echo -en "$m\t$f\t"
    egrep -v '^ *def' lib*|egrep $m|wc -l
done < <(find_priv_methods -d lib*|sort)
