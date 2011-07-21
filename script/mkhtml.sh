#!/bin/bash
. ~/lib/libcsv.sh
id=${1%*=};shift
setfld $id || _usage_key
file=$HOME/.var/json/first.html
#<link rel="stylesheet" type="text/css" href="/ciax-style.css" />
cat > $file <<EOF
<html>
<head>
<title>CIAX-XML</title>
<style type"text/css">
body{
  background-image : url(/bg-1.jpg);
  background-repeat : repeat;
  background-attachment : fixed;
  color : #000066;
  background-color : white;
}
h1{
  text-align : center;
}
table{
  width : 70%;
  border : 5px outset #aadd99;
  margin-left : 15%;
  margin-right : 15%;
}
th{
  font-size : x-large;
  text-align : center;
  color : white;
  background-color:#aadd99;
}
td{
  border : 3px inset
}

.label{
  color : blue;
}
.normal{
  color : green;
}
.alarm{
  color : red;
}
.warn{
  color : yellow;
}
</style>
<script type="text/javascript" src="http://ajax.googleapis.com/ajax/libs/jquery/1.6.2/jquery.min.js"></script>
<script type="text/javascript">
function update(){
  jQuery.ajax({
    url : "status_$obj.json",
    dataType : 'json',
    cache : false,
    success : function(json){
      for (var h in json){
        jQuery("#"+h).text(json[h]);
      }
    }
  })
}
jQuery(document).ready(setInterval(update,3000));
</script>
</head>
<body>
EOF
>>$file htmltbl $obj $cls
cat >> $file <<EOF
</body>
</html>
EOF
