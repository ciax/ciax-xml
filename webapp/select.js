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
    return id;

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
    if (data) {
        var list = data.list.sort(date_sort);
        var size = $('#select li').size();
        for (var i = size; i < list.length; i++) {
            make_item(list[i]);
        }
    }
    activate();

    // Latest Top
    function date_sort(a, b) {
        var na = a.id - 0;
        var nb = b.id - 0;
        if (na < nb) return -1;
        if (na > nb) return 1;
        return 0;
    }

    function activate() {
        var sel = $('#select li.selected');
        if (!sel[0]) {
            sel = $('#select li').first();
            sel.addClass('selected');
        }
        var id = sel.attr('id');
        if (sel.children('em').text() == 'busy') {
            start_upd(id);
        }else {
            stop_upd();
        }
        archive(id);
    }
}

function update_list() {
    get_update('rec_list.json', make_list);
}

// Initial Setting
function init_log() {
    // Register Events
    init_record_event();
    set_acordion('#select');
    // Set click event
    $('#select').on('click', 'li', function() {
        if ($(this).hasClass('selected')) {
            acordion('#record h4');
        }else {
            $('#select li').removeClass('selected');
            $(this).addClass('selected');
            update_list();
        }
    });
    // Set first selected
    get_static('rec_list.json', function(data) {
        make_list(data);
        acordion('#select h4:not(:first)');
    });
}
