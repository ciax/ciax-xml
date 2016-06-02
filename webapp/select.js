// Recommended Package: closure-linter
// fixjsstyle select.js
// Listing part
function make_item(hash) {
    var html_sel = [];
    var id = hash.id;
    // Date(j-0) -> cast to num
    var time = new Date(id - 0);
    html_sel.push('<li id="' + id + '">');
    record_time();
    record_cmd();
    record_res(hash.result);
    html_sel.push('</li>');
    make_date().prepend(html_sel.join(''));

    function record_time() {
        html_sel.push('<span class="time" title="' + id + '">');
        html_sel.push(time.toLocaleTimeString());
        html_sel.push('</span>');
    }
    function record_cmd() {
        html_sel.push(' <span class="cmd">[' + hash.cid + ']</span>');
    }
    function record_res(res) {
        html_sel.push(' -> ');
        html_sel.push('<em class="res ' + res + '">' + res + '</em>');
    }
    function make_date() {
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
    var html_sel = [];
    var date;
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

// Register Events
function select_list() {
    var par = {dataType: 'json', ifModified: true, success: make_list};
    var current = 'latest';
//    var int;
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
    // Set initial selection
    $.getJSON('rec_list.json', function(data) {
        make_list(data);
        current = $('#select li:first').attr('id');
        acordion('#select h4:not(:first)');
        activate();
    });
    return update_list;

    function update_list() {
        $.ajax('rec_list.json', par);
        activate();
    }

    function activate() {
        var target = $('#' + current).addClass('selected');
        if (target.children('em').text() == 'busy') {
//            if (int) clearInterval(int);
            start_upd(current);

        }else {
            stop_upd();
//            if (!int) setInterval(update_list, 1000);
        }
        archive(current);
    }
}
// Initial Setting
function init_log() {
    sel_upd = select_list();
}
var sel_upd;
