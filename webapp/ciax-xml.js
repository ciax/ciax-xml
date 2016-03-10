// Need var: Type,Site
var last;
function elapsed(){
    var now=new Date();
    var ms=now.getTime()-last;
    var sign='';
    if(ms < 0){
        ms=-ms;
        sign='-';
    }
    var t=new Date(ms);
    var str;
    if (ms > 86400000){
        str=Math.floor(ms/8640000)/10+" days";
    }else if(ms > 3600000){
        str=t.getHours()+"h "+t.getMinutes()+'m';
    }else{
        str=t.getMinutes()+"' "+t.getSeconds()+'"';
    }
    $("#elapsed").text(sign+str);
}
function conv(stat){
    var data= $.extend({},stat.data,stat.msg);
    for (var id in data){
        if("class" in stat && id in stat.class){
            $("#"+id).addClass(stat.class[id]);
        }
        $("#"+id).text(data[id]);
    }
    last=stat.time;
    var lstr=new Date(last);
    $("#time").text(lstr.toLocaleString());
}
function update(){
    $.getJSON(Type+'_'+Site+'.json',conv);
    elapsed();
}
function init(){
    update();
    setInterval(update,1000);
}
function dvctl(cmd){
    $.post(
        "/json/dvctl-udp.php",
        {host: Host, port: Port, cmd : cmd},
        function(data){
            alert($.parseJSON(data).msg);
            update();
        }
    );
}
function seldv(obj){
    var cmd = obj.options[obj.selectedIndex].value;
    if(cmd != '--select--'){
        alert("ISSUED("+cmd+")");
        dvctl(cmd);
    }
}
$(document).ready(init);
