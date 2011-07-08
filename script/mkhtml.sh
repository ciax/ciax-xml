#!/bin/bash
. ~/lib/libcsv.sh
id=$1;shift
setfld $id || _usage_key
file=$HOME/.var/json/first.html
cat > $file <<EOF
<html>
<head>
<title>CIAX-XML</title>
<link rel="stylesheet" type="text/css" href="/ciax-style.css" />
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
