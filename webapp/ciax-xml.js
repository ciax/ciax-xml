function period(ms){
    var t=new Date(ms);
    if (ms > 86400000){
        return Math.floor(ms/8640000)/10+" days";
    }else if(ms > 3600000){
        return t.getHours()+"h "+t.getMinutes()+'m';
    }else{
        return t.getMinutes()+"'"+t.getSeconds()+'"';
    }
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
            jQuery("#elapse").text(period(ms));
        }
    })
}
jQuery(document).ready(setInterval(update,1000));
