// Get Argument by http://qiita.com/tonkatu_tanaka/items/99d167ded9330dbc4019
function get_arg() {
    var arg = new Object;
    var pair = location.search.substring(1).split('&');
    for (var i = 0; pair[i]; i++) {
        var kv = pair[i].split('=');
        arg[kv[0]] = kv[1];
    }
    return (arg);
}
var par = get_arg();
