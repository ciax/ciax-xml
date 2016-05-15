// Recommended Package: closure-linter
// fixjsstyle select.js
// Listing part
function record_cmd(key, cid) {
    all.push(' <a href="record.php?id=' + key + '" target=frm2>');
    all.push(' <span class="cmd">[' + cid + ']</span>');
    all.push('</a>');
}
function record_res(res) {
    all.push(' -> ');
    all.push('<em class="' + res + '">' + res + '</em>');
}
function time_list(time, hash) {
    all.push('<li>');
    all.push('<span class="time">' + time.toLocaleTimeString() + '</span>');
    record_cmd(hash['id'], hash['cid']);
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
// manipulate other frm
function load_latest() {
    top.frm2.location.href = 'record_latest.html';
}
function static() {
    all = [];
    $.getJSON('rec_list.json', function(data) {
        var keys = [];
        var list = data['list']
        for (var i =0; i < list.length; i++) {
            // Date(j-0) -> cast to num
            date_list(list[i]);
        }
        all.push('</ul>');
        $('#select')[0].innerHTML = all.join('');
        acordion();
        adjust();
        $(window).on('resize', adjust);
    });
    $('.mcr').after(' <button name="latest" onclick="load_latest()">latest</button>');
}
// Initialize
var all = [];
var date = new Date();
$(document).ready(static);
