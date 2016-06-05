// Recommended Package: closure-linter
// fixjsstyle select.js
// Listing part
function make_item(hash) {
    var html = [];
    var id = hash.id;
    var time = new Date(id - 0);
    // Date(j-0) -> cast to num
    html.push('<li id="' + id + '">');
    _line();
    html.push('</li>');
    return html.join('');

    function _line() {
        _time();
        _cmd();
        _res(hash.result);
    }

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
        html.push('<em class="' + res + '">' + res + '</em>');
    };
}


function make_list(data) {
    if (data) {
        var jary = data.list.sort(date_sort);
        var liary = $('#select li');
        var len = liary.length;
        console.log(jary.length + ' vs ' + len);
        if (len == jary.length) {
            var item = jary[len - 1];
            console.log('replace' + JSON.stringify(item));
            $('#' + item.id).replaceWith(make_item(item));
        }else {
            for (var i = len; i < jary.length; i++) {
                var item = jary[i];
                console.log('add' + JSON.stringify(item));
                make_date(item).prepend(make_item(item));
            }
        }
    }
    activate();

    function make_date(hash) {
        var time = new Date(hash.id - 0);
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
            stop_upd();
            start_upd(update_record);
        }else {
            start_upd(update_list);
        }
        archive(id);
        blinking();
    }
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
    $('#select').on('click', update_list);
    $('#select').on('click', 'li', switch_select);
    // Set first selected
    ajax_static('rec_list.json', function(data) {
        make_list(data);
        acordion('#select h4:not(:first)');
    });

    function switch_select() {
        if ($(this).hasClass('selected')) return;
        $('#select li').removeClass('selected');
        $(this).addClass('selected');
    }

}
