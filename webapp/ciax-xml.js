function update(){
    jQuery.ajax({
        url : File,
        dataType : 'json',
        cache : false,
        success : function(view){
            var stat=view.stat
            for (var id in stat){
                var val=stat[id];
                if(id == "elapse"){
                    var d=new Date()-new Date(stat.time);
                    val=Math.round(d/1000+0.5);
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
jQuery(document).ready(setInterval(update,1000));
