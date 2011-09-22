function elapse(){
    var time=$("#time").text();
    if(time.match(/\*+/)) return;
    var ms=new Date()-new Date(time);
    var t=new Date(ms);
    var str;
    if (ms > 86400000){
        str=Math.floor(ms/8640000)/10+" days";
    }else if(ms > 3600000){
        str=t.getHours()+"h "+t.getMinutes()+'m';
    }else{
        str=t.getMinutes()+"' "+t.getSeconds()+'"';
    }
    $("#elapse").text(str);
}
function conv(view){
    var stat=view.stat
    for (var id in stat){
        var val=stat[id];
        if(view.symbol && view.symbol[id]){
            var hash=view.symbol[id];
            $("#"+id).addClass(hash.class);
            val=hash.msg;
        }
        $("#"+id).text(val);
    }
}
function update(){
    $.get(File,null,conv,'json');
    elapse();
}
function init(){
    update();
    setInterval(update,1000);
}
$(document).ready(init);
