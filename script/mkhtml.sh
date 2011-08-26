#!/bin/bash
. ~/lib/libcsv.sh
src=$HOME/ciax-xml/webapp
dir=$HOME/.var/json

symout(){
    sdb=symbol_$1.js
    jsdb $1 $2 > $dir/$sdb
}

for id; do
    setfld $id || _usage_key
    file=$dir/$id.html
    symout $obj $app
    ln -sf $src/* $dir/
    cat > $file <<EOF
<html>
<head>
<title>CIAX-XML</title>
<link rel="stylesheet" type="text/css" href="ciax-xml.css" />
<script type="text/javascript" src="http://ajax.googleapis.com/ajax/libs/jquery/1.6.2/jquery.min.js"></script>
<script type="text/javascript" src="$sdb"></script>
<script type="text/javascript" src="symbol_all.js"></script>
<script type="text/javascript" src="symconv.js"></script>
<body onload="update();">
EOF
>>$file htmltbl $obj $app
cat >> $file <<EOF
</body>
</html>
EOF
echo "$file created"
done
symout all
