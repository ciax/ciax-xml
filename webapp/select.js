// Recommended Package: closure-linter
// fixjsstyle select.js
// Listing part
function record_cmd(cid) {
    all.push(' <span class="cmd">[' + cid + ']</span>');
}
function record_res(res) {
    all.push(' -> ');
    all.push('<em class="' + res + '">' + res + '</em>');
}
function time_list(time, hash) {
    all.push('<li id="' + hash['id'] + '">');
    all.push('<span class="time">' + time.toLocaleTimeString() + '</span>');
    record_cmd(hash['cid']);
    record_res(hash['result']);
    all.push('</li>');
}

function date_list(hash) {
    var time = new Date(hash['id'] - 0);
    var crd = time.toLocaleDateString();
    if (date != crd) {
        if (all.length > 0) { all.push('</ul>'); }
        all.push('<h4>' + crd + '</h4><ul style="display:none;">');
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
// manipulate other frm
function load_latest() {
    top.frm2.location.href = 'record_latest.html';
}
function set_event() {
    $('li').on('click', function() {
        var id = $(this).attr('id');
        top.frm2.archive(id);
    });
}
function archive() {
    all = [];
    $.getJSON('rec_list.json', function(data) {
        var keys = [];
        var list = data['list'].sort(date_sort);
        for (var i = 0; i < list.length; i++) {
            // Date(j-0) -> cast to num
            date_list(list[i]);
        }
        all.push('</ul>');
        $('#select')[0].innerHTML = all.join('');
        load_latest();
        set_event();
        acordion();
        height_adjust();
    });
    $(window).on('resize', height_adjust);
    $('.mcr').after(' <button name="latest" onclick="load_latest()">latest</button>');
}
// Initialize
var all = [];
var date = new Date();
$(document).ready(archive);
