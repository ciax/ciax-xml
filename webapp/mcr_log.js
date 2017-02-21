// Recommended Package: closure-linter
// fixjsstyle mcr_log.js
// Listing part
function make_item(data) {
    function _line() {
        _time();
        _cmd();
        _res(data.result);
    }

    function _time() {
        html.push('<span class="time" title="' + id + '">');
        html.push(time.toLocaleTimeString('en-US', {hour12: false}));
        html.push('</span>');
    }
    function _cmd() {
        html.push(' <span class="cmd">[' + data.cid + ']</span>');
    }
    function _res(res) {
        html.push(' -> ');
        html.push('<em class="' + res + '">' + res + '</em>');
    };

    var html = [];
    var id = data.id;
    var time = new Date(id - 0);
    // Date(j-0) -> cast to num
    html.push('<li id="' + id + '">');
    _line();
    html.push('</li>');
    return html.join('');
}

function func_make_list() {
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

    function _make_year(time){
        var cyr = time.getFullYear();
        if(year != cyr){
            year=cyr;
            _make_tree(year, year, 'log');
        }
    }

    function _make_date(time) {
        var dary = time.toLocaleDateString().split('/');
        var dti = dary[1] + '/' + dary[2];
        var did = dary.join('_');
        if (!$('#' + did)[0]) {
            _make_year(time);
            _make_tree(dti, did, year);
        }
        return $('#' + did);
    }

    // Latest Top
    function _make_tree(title, id, pid){
        var html = [];
        html.push('<h4>' + title + '</h4>');
        html.push('<ul id="' + id + '"></ul>');
        $('#'+pid).prepend(html.join(''));
    }

    function _sort_date(a, b) {
        var na = a.id - 0;
        var nb = b.id - 0;
        if (na < nb) return -1;
        if (na > nb) return 1;
        return 0;
    }

    function _upd_line(i, item) {
        var time = new Date(item.id - 0);
        _upd_item(item) || _make_date(time).prepend(make_item(item));
    }

    function _init_log() {
        // Set first selected
        set_acordion('#log')(':gt(1)');
        $('#log li').first().trigger('click');
        again = 1;
    }

    function _init_make_list(data){
        if (!data) return;
        var jary = data.list.sort(_sort_date);
        $.each(jary, _upd_line);
        // blinking status
        blinking();
        if(!again) _init_log();
    }
    var year = '';
    var again;
    return _init_make_list;
}


function update_list() {
    ajax_update('rec_list.json').done(make_list);
}

function toggle_dvctl() {
    $('.dvctl').fadeToggle(1000, height_adjust);
}

function switch_record(id) {
    $('#log li').removeClass('selected');
    $('#' + id).addClass('selected');
    // Activate selected record
    update_record(id);
}

// Initial Setting
function init_log() {
    function _on_click() {
        if ($(this).hasClass('selected')) return;
        switch_record($(this).attr('id'));
    }

    // Set click event
    $('#log').on('click', 'li', _on_click);
    upd_list.log = update_list;
}
var make_list = func_make_list();
init_list.push(init_log);
