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
function record_time(id, time) {
    html_sel.push('<span class="time" title="' + id + '">');
    html_sel.push(time.toLocaleTimeString());
    html_sel.push('</span>');
}
function time_list(time, hash) {
   var id = hash['id'];
    html_sel.push('<li id="' + id + '">');
    record_time(hash['id'], time);
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
function make_list(data) {
    html_sel = [];
    var list = data['list'].sort(date_sort);
    for (var i = 0; i < list.length; i++) {
        date_list(list[i]);
    }
    html_sel.push('</ul>');
    $('#select')[0].innerHTML = html_sel.join('');
}
function select_record(target) {
    $('#' + current).removeClass('selected');
    $(target).addClass('selected');
    current = $(target).attr('id');
}
function set_select_event() {
    $('#select li').on('click', function() {
        if ($(this).attr('id') == current) {
            acordion('#record h4');
        }else {
            select_record(this);
            archive(current);
        }
    });
}
function init_log() {
    $.getJSON('rec_list.json', function(data) {
        make_list(data);
        set_select_event();
        set_acordion('#select h4', ':not(:first)');
        height_adjust();
        select_record('#select li:first');
        update(current);
    });
}
// Initialize
var html_sel = [];
var date = new Date();
var current = '';
