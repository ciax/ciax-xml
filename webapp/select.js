// Recommended Package: closure-linter
// fixjsstyle select.js
// Listing part
function make_item(hash) {
    var html = [];
    var id = hash.id;
    // Date(j-0) -> cast to num
    var time = new Date(id - 0);
    html.push('<li id="' + id + '">');
    _time();
    _cmd();
    _res(hash.result);
    html.push('</li>');
    _date().prepend(html.join(''));

    function _time() {
        html.push('<span class="time" title="' + id + '">');
        html.push(time.toLocaleTimeString());
        html.push('</span>');
    }
    function _cmd() {
        html.push(' <span class="cmd">[' + hash.cid + ']</span>');
    }
    function _res(res) {
        html.push(' -> ');
        html.push('<em class="res ' + res + '">' + res + '</em>');
    }
    function _date() {
        var crd = time.toLocaleDateString();
        var did = crd.replace(/\//g, '_');
        if (!$('#' + did)[0]) {
            var html = [];
            html.push('<h4>' + crd + '</h4>');
            html.push('<ul id="' + did + '"></ul>');
            $('#select').prepend(html.join(''));
        }
        return $('#' + did);
    }
}

function make_list(data) {
    if (!data) return;
    var list = data.list.sort(date_sort);
    var size = $('#select li').size();
    for (var i = size; i < list.length; i++) {
        make_item(list[i]);
    }
    // Latest Top
    function date_sort(a, b) {
        var na = a.id - 0;
        var nb = b.id - 0;
        if (na < nb) return -1;
        if (na > nb) return 1;
        return 0;
    }
}

function activate() {
    var target = $('#' + current).addClass('selected');
    if (target.children('em').text() == 'busy') {
        start_upd(current);
    }else {
        stop_upd();
    }
    archive(current);
}

function update_list() {
    $.getJSON('rec_list.json', make_list);
    activate();
}

// Initial Setting
function init_log() {
    // Register Events
    init_record_event();
    set_acordion('#select');
    // Set click event
    $('#select').on('click', 'li', function() {
        if ($(this).attr('id') == current) {
            acordion('#record h4');
        }else {
            $('#select li').removeClass('selected');
            current = $(this).attr('id');
            activate();
        }
    });
    // Set first selected
    $.getJSON('rec_list.json', function(data) {
        make_list(data);
        current = $('#select li:first').attr('id');
        acordion('#select h4:not(:first)');
        activate();
    });
}
var current = 'latest';
