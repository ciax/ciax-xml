// Recommended Package: closure-linter
// fixjsstyle select.js
// Listing part
function record_cmd(cid) {
    html_sel.push(' <span class="cmd">[' + cid + ']</span>');
}
function record_res(res) {
    html_sel.push(' -> ');
    html_sel.push('<em class="' + res + '">' + res + '</em>');
}
function time_list(time, hash) {
    html_sel.push('<li id="' + hash['id'] + '">');
    html_sel.push('<span class="time">' + time.toLocaleTimeString() + '</span>');
    record_cmd(hash['cid']);
    record_res(hash['result']);
    html_sel.push('</li>');
}

function date_list(hash) {
    // Date(j-0) -> cast to num
    var time = new Date(hash['id'] - 0);
    var crd = time.toLocaleDateString();
    if (date != crd) {
        if (html_sel.length > 0) { html_sel.push('</ul>'); }
        html_sel.push('<h4>' + crd + '</h4><ul>');
        date = crd;
    }
    time_list(time, hash);

}
function date_sort(a, b) {
    var na = a['id'] - 0;
    var nb = b['id'] - 0;
    if (na < nb) return 1;
    if (na > nb) return -1;
    return 0;
}
function set_event() {
    $('#select li').on('click', function() {
        var id = $(this).attr('id');
        archive(id);
    });
}
function select() {
    $.getJSON('rec_list.json', function(data) {
        html_sel = [];
        var list = data['list'].sort(date_sort);
        for (var i = 0; i < list.length; i++) {
            date_list(list[i]);
        }
        html_sel.push('</ul>');
        $('#select')[0].innerHTML = html_sel.join('');
        set_event();
        acordion('#select');
        height_adjust();
    });
}
// Initialize
var html_sel = [];
var date = new Date();
