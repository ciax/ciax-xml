#!/bin/bash
JQUERY=1.7.2
[ "$1" ] || { libhtmltbl.rb; exit; }
src=$HOME/ciax-xml/webapp
dir=$HOME/.var/json
install $src/* $dir/
tmpfile="$dir/temp"
for id; do
    file=$dir/$id.html
    libhtmltbl.rb $id > $tmpfile || break
    cat > $file <<EOF
<html>
<head>
<title>CIAX-XML</title>
<link rel="stylesheet" type="text/css" href="ciax-xml.css" />
<script type="text/javascript" src="http://ajax.googleapis.com/ajax/libs/jquery/1.10.1/jquery.min.js"></script>
<script type="text/javascript">var File="status_$id.json";</script>
<script type="text/javascript" src="ciax-xml.js"></script>
</head>
<body>
EOF
    cat $tmpfile >> $file
    cat >> $file <<EOF
</body>
</html>
EOF
echo "$file created"
done
rm $tmpfile