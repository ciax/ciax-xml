var last;
function elapse(){
    var now=new Date()
    var ms=now.getTime()-last;
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
        if(view.class && view.class[id]){
                $("#"+id).addClass(view.class[id]);
        }
        if(view.msg && view.msg[id]){
            val=view.msg[id]
        }
        $("#"+id).text(val);
    }
    last=stat.time*1000;
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
