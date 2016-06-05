// Recommended Package: closure-linter
// fixjsstyle select.js
// Listing part
function make_item(data) {
    var html = [];
    var id = data.id;
    var time = new Date(id - 0);
    // Date(j-0) -> cast to num
    html.push('<li id="' + id + '">');
    _line();
    html.push('</li>');
    return html.join('');

    function _line() {
        _time();
        _cmd();
        _res(data.result);
    }

    function _time() {
        html.push('<span class="time" title="' + id + '">');
        html.push(time.toLocaleTimeString());
        html.push('</span>');
    }
    function _cmd() {
        html.push(' <span class="cmd">[' + data.cid + ']</span>');
    }
    function _res(res) {
        html.push(' -> ');
        html.push('<em class="' + res + '">' + res + '</em>');
    };
}

function make_list(data) {
    if (!data) return;
    var jary = data.list.sort(_sort_date);
    $.each(jary, function(i, item) {
        _upd_item(item) || _make_date(item).prepend(make_item(item));
    });
    _init_select();
    blinking();

    function _upd_item(data) {
        var jq = $('#' + data.id);
        if (!jq[0]) return;
        var em = jq.children('em');
        if (em.text() == 'busy') {
            var res = data.result;
            em.text(res).attr('class', res);
        }
        return true;
    }

    function _make_date(data) {
        var time = new Date(data.id - 0);
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

    // Latest Top
    function _sort_date(a, b) {
        var na = a.id - 0;
        var nb = b.id - 0;
        if (na < nb) return -1;
        if (na > nb) return 1;
        return 0;
    }

    function _init_select() {
        var jq = $('#select li.selected');
        if (jq[0]) return jq;
        $('#select li').first().trigger('click');
    }
}
// Activate selected record
function activate(jq) {
    var id = jq.attr('id');
    stop_upd();
    if (jq.children('em').text() == 'busy') {
        start_upd(update_record);
    }else {
        start_upd(update_list);
    }
    archive(id);
}

function update_list() {
    ajax_update('rec_list.json', make_list);
}

// Initial Setting
function init_log() {
    // Register Events
    init_record_event();
    set_acordion('#select');
    // Set click event
    $('#select').on('click', 'li', switch_select);
    // Set first selected
    ajax_static('rec_list.json', function(data) {
        make_list(data);
        acordion('#select h4:not(:first)');
    });

    function switch_select() {
        if ($(this).hasClass('selected')) return;
        $('#select li').removeClass('selected');
        activate($(this).addClass('selected'));
    }
}
