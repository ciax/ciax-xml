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
            $('#' + id).attr('class',stat.class[id]);
        }
        $('#' + id).text(data[id]);
    }
    last = stat.time;
    var lstr = new Date(last);
    $('#time').text(lstr.toLocaleString());
}
function update() {
    $.getJSON(type + '_' + site + '.json', conv);
    elapsed();
}
// Need var: Type,Site
var last;
var offset = 0;
