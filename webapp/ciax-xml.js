// Need var: Type,Site
var last;
var offset = 0;
function elapsed() {
    var now = new Date();
    var ms = now.getTime() - last + offset;
    if (ms < 0) { offset = -ms; ms = 0;}
    var t = new Date(ms);
    var str;
    if (ms > 86400000) {
        str = Math.floor(ms / 8640000) / 10 + ' days';
    }else if (ms > 3600000) {
        str = t.getHours() + 'h ' + t.getMinutes() + 'm';
    }else {
        str = t.getMinutes() + "' " + t.getSeconds() + '"';
    }
    $('#elapsed').text(str);
}
function conv(stat) {
    var data = $.extend({},stat.data, stat.msg);
    for (var id in data) {
        if ('class' in stat && id in stat.class) {
            $('#' + id).addClass(stat.class[id]);
        }
        $('#' + id).text(data[id]);
    }
    last = stat.time;
    var lstr = new Date(last);
    $('#time').text(lstr.toLocaleString());
}
function update() {
    $.getJSON(Type + '_' + Site + '.json', conv);
    elapsed();
}
function init() {
    update();
    setInterval(update, 1000);
}
function dvctl(cmd) {
    $.post(
        '/json/dvctl-udp.php',
        {port: Port, cmd: cmd},
        function(data) {
            $('#msg').text($.parseJSON(data).msg);
            update();
        }
    );
}
function seldv(obj) {
    var cmd = obj.options[obj.selectedIndex].value;
    if (cmd != '--select--') {
        var res = confirm('EXEC?(' + cmd + ')');
        if (res) { dvctl(cmd); }
    }
}
$(document).ready(init);
