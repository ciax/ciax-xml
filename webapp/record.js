// Recommended Package: closure-linter
// fixjsstyle record.js
// ********* Steps **********
// step header section
function make_step(step) {
    var html = ['<li id="' + step.time + '">'];
    _header();
    _conditions() || _sub_mcr();
    html.push('</li>');
    return html.join('');

    function _title() {
        var type = step.type;
        html.push('<span class="head ' + type + '">' + type + '</span>');
        html.push('<span class="cmd">');
        if (step.label) html.push(': ' + step.label);
        var ary = [];
        if (step.site) { ary.push(step.site); }
        if (step.args) { ary = ary.concat(step.args); }
        if (step.val) { ary.push(step.val); }
        if (ary.length > 0) {html.push(': [' + ary.join(':') + ']');}
        html.push('</span>');
    }
    // result section
    function _result() {
        var res = step.result;
        if (!res || res == 'busy') return;
        html.push(' -> ');
        html.push('<em class="' + res + '">' + res + '</em>');
    }
    function _action() {
        if (!step.action) return;
        html.push(' <span class="action">(');
        html.push(step.action);
        html.push(')</span>');
    }
    // elapsed time section
    function _time() {
        var crnt = new Date(step.time);
        var elps = ((crnt - start_time) / 1000).toFixed(2);
        html.push('<span class="elps tail" title="' + crnt.toTimeString() + '">[');
        html.push(elps + ']</span>');
    }
    // waiting step
    function _meter(max) {
        html.push(' <meter value="' + step.count / max * 100 + '" max="100"');
        if (step.retry) html.push('low="70" high="99"');
        html.push('>(' + step.count + '/' + max + ')</meter>');
    }
    function _count() {
        if (!step.count) return;
        var max = step.retry || step.val;
        if (step.type != 'mcr') _meter(max);
        html.push('<span>(' + step.count + '/' + max + ')</span>');
        if (step.busy) html.push(' -> <em class="active">Busy</em>');
    }
    // other steps
    function _header() {
        html.push('<h4>');
        _title();
        _count();
        _result();
        _action();
        _time();
        html.push('</h4>');
    }
    // condition step
    function _operator(ope, cri) {
        switch (ope) {
        case 'equal': return ('== ' + cri); break;
        case 'not' : return ('!= ' + cri); break;
        case 'match' : return ('=~ /' + cri + '/'); break;
        case 'unmatch' : return ('!~ /' + cri + '/'); break;
        default:
        }
    }
    function _conditions() {
        if (!step.conditions) return;
        html.push('<ul>');
        $.each(step.conditions, function(k, cond) {
            var res = cond.res;
            html.push('<li>');
            html.push('<var>' + cond.site + ':' + cond.var + '(' + cond.form + ')</var>');
            html.push('<code>' + _operator(cond.cmp, cond.cri) + '?</code>  ');
            if (step.type == 'goal' && res == false) res = 'warn';
            html.push('<span class="' + res + '"> (' + cond.real + ')</span>');
            html.push('</li>');
        });
        html.push('</ul>');
        return true;
    }
    function _sub_mcr() {
        if (step.type != 'mcr') return;
        html.push('<ul class="depth' + (step.depth - 0 + 1) + '"></ul>');
    }

}

// ********* Outline **********
// *** Display on the Bars ***
function record_outline(data) { // Do at the first
    start_time = new Date(data.start);
    $('#mcrcmd').text(data.label + ' [' + data.cid + ']');
    $('#date').text(new Date(data.id - 0)).attr('title', data.id);
    $('#total').text('');
    replace('#result', '');
    record_steps(data);
}
// Macro Body
function record_steps(data) {
    $('#record ul').empty();
    $.each(data.steps, function(i, step) {
        $('#record .depth' + step.depth + ':last').append(make_step(step));
    });
    sticky_bottom('slow');
    record_status(data);
}
function record_status(data) {
    replace('#status', data.status);
}
function record_result(data) { // Do at the end
    replace('#result', data.result);
    replace('#' + data.id + ' em', data.result);
    var last = new Date(data.time);
    $('#total').text('[' + data.total_time + ']').attr('title', last.toTimeString());
}

// ******** Dynamic Page ********
function dynamic_page() {
    // **** Updating Page ****
    var last_time = '';  // For detecting update
    var first_time = ''; // For first time at a new macro;
    var steps_length = 0;
    var suspend = false;
    return function(tag) { // To be update
        ajax_record(tag, upd_record, function() { suspend = true;});
        blinking();
    }
    function upd_record(data, status) {
        if (status != 'success') return;
        if (first_time != data.id) { // Do only the first one for new macro
            record_first(data);
            first_time = data.id;
        }else if (data.time != last_time) { // Do every time for updated record
            record_update(data);
            last_time = data.time;
        }
    }
    // Update Command Selector
    function record_commands(ary) {
        var sel = $('#query select')[0];
        if (sel) make_select(sel, ary);
    }
    function init_commands() {
        var slots = [];
        for (var i = 0; i <= 23; i++) { slots.push('slot' + i); }
        var ary = ['upd'];
        ary.push(['init', ['tinit', 'cinit']]);
        ary.push(['mos', ['start', 'load', 'store', 'fin', 'kapa', 'kapa1']]);
        ary.push(['slot', slots]);
        record_commands(ary);
    }
    // Update Content of Steps (When JSON is updated)
    function append_step(data) {
        // When Step increases.
        for (var i = steps_length; i < data.steps.length; i++) {
            var step = data.steps[i];
            $('.depth' + step.depth + ':last').append(make_step(step));
        }
        steps_length = i;
        sticky_bottom('slow');
        record_status(data);
    }
    function update_steps(data) {
        var crnt = data.steps.length;
        if (steps_length == crnt) {
            // When Step doesn't increase.
            var step = data.steps[crnt - 1];
            $('#' + step.time).html(make_step(step));
            suspend = true;
        }else if (suspend) {
            record_steps(data);
            steps_length = crnt;
            suspend = false;
        }else {
            append_step(data);
        }
    }

    // **** Make Pages ****
    function mcr_end(data) {
        record_steps(data);
        record_result(data);
        init_commands();
        stop_upd();
    }
    function record_first(data) {
        port = data.port;
        record_outline(data); // Make record one time
        var stat = data.status;
        if (stat == 'end') {
            mcr_end(data);
        }else { //run
            if (stat == 'query') record_commands(data.option);
            start_upd('latest');
        }
        steps_length = data.steps.length;
    }
    function record_update(data) {
        var stat = data.status;
        if (stat == 'end') {
            mcr_end(data);
        }else {
            if (stat == 'query') record_commands(data.option);
            update_steps(data); // Make record one by one
        }
    }
}
// ******** Static Page *********
function static_page(data, status) {
    if (status != 'success') return;
    record_outline(data);
    record_result(data);
}

// ******** Ajax ********
// func1 for updated, func2 for no changes
function ajax_record(tag, func1, func2) {
    tag = tag ? tag : 'latest';
    ajax_update('record_' + tag + '.json', func1, func2);
}
function archive(tag) {
    // Read whether src is updated or not
    ajax_record(tag, static_page);
}

// ******** Command ********
function selmcr(obj) {
    var cmd = get_select(obj);
    if (!cmd) return;
    exec(cmd, function() {
        make_select(obj, []);
        start_upd();
    });
}

// ******** Init Page ********
function init_record_event() {
    height_adjust();
    set_acordion('#record');
    set_auto_release('#record');
}
function init_record() {
    init_record_event();
    update('latest');
}
// Var setting
var update = dynamic_page();
var start_time; // For elapsed time
