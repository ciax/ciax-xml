function update(){
    jQuery.ajax({
        url : File,
        dataType : 'json',
        cache : false,
        success : function(view){
            var stat=view.stat
            for (var id in stat){
                var val=stat[id];
                if(view.symbol && view.symbol[id]){
                    var hash=view.symbol[id];
                    jQuery("#"+id).addClass(hash.class);
                    val=hash.msg;
                }
                jQuery("#"+id).text(val);
            }
            var d=new Date(new Date()-new Date(stat.time));
            str=""+d.toUTCString().match(/[0-9]{2}:[0-9]{2}:[0-9]{2}/);
            jQuery("#elapse").text(str);
        }
    })
}
jQuery(document).ready(setInterval(update,1000));
