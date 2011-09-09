#!/bin/bash
. ~/lib/libcsv.sh
src=$HOME/ciax-xml/webapp
dir=$HOME/.var/json

for id; do
    setfld $id || _usage_key
    file=$dir/$id.html
    ln -sf $src/* $dir/
    cat > $file <<EOF
<html>
<head>
<title>CIAX-XML</title>
<link rel="stylesheet" type="text/css" href="ciax-xml.css" />
<script type="text/javascript" src="http://ajax.googleapis.com/ajax/libs/jquery/1.6.2/jquery.min.js"></script>
<script type="text/javascript">
function update(){
    jQuery.ajax({
        url : "status_$id.json",
        dataType : 'json',
        cache : false,
        success : function(view){
            for (var id in view.stat){
                var val=view.stat[id];
                if(view.symbol && view.symbol[id]){
                    var hash=view.symbol[id];
                    jQuery("#"+id).addClass(hash.class);
                    val=hash.msg;
                }
                jQuery("#"+id).text(val);
            }
        }
    })
}
jQuery(document).ready(setInterval(update,3000));
</script>
<body onload="update();">
EOF
>>$file htmltbl $id $app
cat >> $file <<EOF
</body>
</html>
EOF
echo "$file created"
done
