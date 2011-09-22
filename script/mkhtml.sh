#!/bin/bash
. ~/lib/libcsv.sh
src=$HOME/ciax-xml/webapp
dir=$HOME/.var/json
[[ $1 == '-i' ]] && { opt=$1; shift; }
for id; do
    setfld $id || _usage_key "(-i)"
    file=$dir/$id.html
    if [ "$opt" ] ; then
	install $src/* $dir/
    else
	ln -sf  $src/* $dir/
    fi
    cat > $file <<EOF
<html>
<head>
<title>CIAX-XML</title>
<link rel="stylesheet" type="text/css" href="ciax-xml.css" />
<script type="text/javascript" src="http://ajax.googleapis.com/ajax/libs/jquery/1.6.2/jquery.js"></script>
<script type="text/javascript">var File="status_$id.json";</script>
<script type="text/javascript" src="ciax-xml.js"></script>
<body onload="update();">
EOF
>>$file htmltbl $id $app
cat >> $file <<EOF
</body>
</html>
EOF
echo "$file created"
done
