function time(ms){
    var utc=new Date(ms).toUTCString();
    return ''+utc.match(/[0-9:]{8}/);
}
function days(ms){
    return Math.floor(ms/8640000)/10+"days";
}
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
            var ms=new Date()-new Date(stat.time);
            var str = (ms > 86400000) ? days(ms) : time(ms);
            jQuery("#elapse").text(str);
        }
    })
}
jQuery(document).ready(setInterval(update,1000));
