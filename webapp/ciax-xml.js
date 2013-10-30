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
function conv(stat){
    var val=stat.val
    for (var id in val){
        var msg=val[id];
        if("class" in stat && id in stat["class"]){
                $("#"+id).addClass(stat["class"][id]);
        }
        if("msg" in stat && id in stat["msg"]){
            msg=stat.msg[id]
        }
        $("#"+id).text(msg);
    }
    last=val.time;
}
function update(){
    $.getJSON(File,conv);
    elapse();
}
function init(){
    update();
    setInterval(update,1000);
}
$(document).ready(init);
