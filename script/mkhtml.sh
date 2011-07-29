#!/bin/bash
. ~/lib/libcsv.sh
id=${1%*=};shift
setfld $id || _usage_key
dir=$HOME/.var/json
file=$dir/$id.html
sdb=symbol_$obj.js
jsdb $obj $cls > $dir/$sdb
cp symconv.js $dir/
cp ciax-xml.css $dir/
cat > $file <<EOF
<html>
<head>
<title>CIAX-XML</title>
<link rel="stylesheet" type="text/css" href="ciax-xml.css" />
<script type="text/javascript" src="http://ajax.googleapis.com/ajax/libs/jquery/1.6.2/jquery.min.js"></script>
<script type="text/javascript" src="$sdb"></script>
<script type="text/javascript" src="symconv.js"></script>
<body onload="update();">
EOF
>>$file htmltbl $obj $cls
cat >> $file <<EOF
</body>
</html>
EOF
