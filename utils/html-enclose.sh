#!/bin/bash
JQUERY=1.7.2
cat <<EOF
<html>
<head>
<title>CIAX-XML</title>
<link rel="stylesheet" type="text/css" href="ciax-xml.css" />
<script type="text/javascript" src="http://ajax.googleapis.com/ajax/libs/jquery/1.10.1/jquery.min.js"></script>
<script type="text/javascript">var Type="status",Site="$1";</script>
<script type="text/javascript" src="ciax-xml.js"></script>
</head>
<body>
EOF
cat
cat <<EOF
</body>
</html>
EOF
