function update(){
    jQuery.ajax({
        url : "status_"+ID+".json",
        dataType : 'json',
        cache : false,
        success : function(view){
            var stat=view.stat
            for (var id in stat){
                var val=stat[id];
                switch(id){
                case "time":
                    var d1=new Date(stat.time*1000);
                    val=d1.toString;
                    break;
                case "elapse":
                    var d=new Date().getTime()/1000-stat.time;
                    val=Math.round(d+0.5);
                    break;
                default:;
                }
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
