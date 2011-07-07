#!/bin/bash
. ~/lib/libcsv.sh
cat <<EOF
<html>
<head>
<title>CIAX-XML</title>
<link rel="stylesheet" type="text/css" href="/ciax-style.css" />
</head>
<body>
EOF
htmltbl $*
cat <<EOF
</body>
</html>
EOF
