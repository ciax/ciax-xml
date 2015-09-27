var last;
function elapsed(){
    var now=new Date();
    var ms=now.getTime()-last;
    if(ms < 0){ ms=0; }
    var t=new Date(ms);
    var str;
    if (ms > 86400000){
        str=Math.floor(ms/8640000)/10+" days";
    }else if(ms > 3600000){
        str=t.getHours()+"h "+t.getMinutes()+'m';
    }else{
        str=t.getMinutes()+"' "+t.getSeconds()+'"';
    }
    $("#elapsed").text(str);
}
function conv(stat){
    var data=stat.data
    for (var id in data){
        var msg=data[id];
        if("class" in stat && id in stat["class"]){
                $("#"+id).addClass(stat["class"][id]);
        }
        if("msg" in stat && id in stat["msg"]){
            msg=stat.msg[id]
        }
        $("#"+id).text(msg);
    }
    last=stat.time;
    var lstr=new Date(last);
    $("#time").text(lstr.toLocaleString());
}
function update(){
    $.getJSON(File,conv);
    elapsed();
}
function init(){
    update();
    setInterval(update,1000);
}
function dvctl(site,cmd){
    $.post(
        "/json/dvctl-exe.php",
        {site: site, cmd : cmd},
        function(data){
            alert("Data Loaded: "+data);
        }
    );
}
$(document).ready(init);
