#!/bin/bash
. ~/lib/libdb.sh entity
JQUERY=1.7.2
[[ $1 == '-i' ]] && { opt=$1; shift; }
[ "$1" ] || _usage_key "(-i<install>)"
src=$HOME/ciax-xml/webapp
dir=$HOME/.var/json
if [ "$opt" ] ; then
    install $src/* $dir/
else
    ln -sf  $src/* $dir/
fi
for id; do
    setfld $id || _usage_key "(-i)"
    file=$dir/$id.html
    cat > $file <<EOF
<html>
<head>
<title>CIAX-XML</title>
<link rel="stylesheet" type="text/css" href="ciax-xml.css" />
<script type="text/javascript" src="http://ajax.googleapis.com/ajax/libs/jquery/1.10.1/jquery.min.js"></script>
<script type="text/javascript">var File="stat_$id.json";</script>
<script type="text/javascript" src="ciax-xml.js"></script>
<body>
EOF
>>$file ~/lib/libhtmltbl.rb $id $app
cat >> $file <<EOF
</body>
</html>
EOF
echo "$file created"
done
