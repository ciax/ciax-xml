function period(){
    var time=jQuery("#time").text();
    var ms=new Date()-new Date(time);
    var t=new Date(ms);
    var str;
    if (ms > 86400000){
        str=Math.floor(ms/8640000)/10+" days";
    }else if(ms > 3600000){
        str=t.getHours()+"h "+t.getMinutes()+'m';
    }else{
        str=t.getMinutes()+"'"+t.getSeconds()+'"';
    }
    jQuery("#elapse").text(str);
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
        }
    })
}
jQuery(document).ready(setInterval(update,10000));
jQuery(document).ready(setInterval(period,1000));
