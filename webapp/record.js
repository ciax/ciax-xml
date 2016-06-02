// Recommended Package: closure-linter
// fixjsstyle record.js
// ********* Steps **********
// step header section
function make_step(step) {
    var html = ['<li id="' + step.time + '">'];
    header();
    conditions() || sub_mcr();
    html.push('</li>');
    return html.join('');

    function title() {
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
    function result() {
        var res = step.result;
        if (!res || res == 'busy') return;
        html.push(' -> ');
        html.push('<em class="res ' + res + '">' + res + '</em>');
    }
    function action() {
        if (!step.action) return;
        html.push(' <span class="action">(');
        html.push(step.action);
        html.push(')</span>');
    }
    // elapsed time section
    function time() {
        var now = new Date(step.time);
        var elps = ((now - start_time) / 1000).toFixed(2);
        html.push('<span class="elps tail" title="' + now.toTimeString() + '">[');
        html.push(elps + ']</span>');
    }
    // waiting step
    function meter(max) {
        html.push(' <meter value="' + step.count / max * 100 + '" max="100"');
        if (step.retry) html.push('low="70" high="99"');
        html.push('>(' + step.count + '/' + max + ')</meter>');
    }
    function count() {
        if (!step.count) return;
        var max = step.retry || step.val;
        if (step.type != 'mcr') meter(max);
        html.push('<span>(' + step.count + '/' + max + ')</span>');
        if (step.busy) html.push(' -> <em class="res active">Busy</em>');
    }
    // other steps
    function header() {
        html.push('<h4>');
        title();
        count();
        result();
        action();
        time();
        html.push('</h4>');
    }
    // condition step
    function operator(ope, cri) {
        switch (ope) {
        case 'equal': return ('== ' + cri); break;
        case 'not' : return ('!= ' + cri); break;
        case 'match' : return ('=~ /' + cri + '/'); break;
        case 'unmatch' : return ('!~ /' + cri + '/'); break;
        default:
        }
    }
    function conditions() {
        var conds = step.conditions;
        if (!conds) return;
        html.push('<ul>');
        for (var k in conds) {
            var cond = conds[k];
            var res = cond.res;
            html.push('<li>');
            html.push('<var>' + cond.site + ':' + cond.var + '(' + cond.form + ')</var>');
            html.push('<code>' + operator(cond.cmp, cond.cri) + '?</code>  ');
            if (step.type == 'goal' && res == false) res = 'warn';
            html.push('<em class="' + res + '"> (' + cond.real + ')</em>');
            html.push('</li>');
        }
        html.push('</ul>');
        return true;
    }
    function sub_mcr() {
        if (step.type != 'mcr') return;
        html.push('<ul class="depth' + (step.depth - 0 + 1) + '"></ul>');
    }

}

// ********* Record **********
// Macro Body
function record_steps(data) {
    for (var i in data.steps) {
        var step = data.steps[i];
        $('.depth' + step.depth + ':last').append(make_step(step));
    }
    sticky_bottom('slow');
    record_status(data);
}

// ********* Outline **********
// *** Display on the Bars ***
function record_outline(data) { // Do at the first
    start_time = new Date(data.start);
    $('#mcrcmd').text(data.label + ' [' + data.cid + ']');
    $('#date').text(new Date(data.id - 0));
    $('#total').text('');
    replace('#result', '');
    $('#record ul').empty();
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

// ******** Static Page *********
function static_page(data, status) {
    if (status != 'success') return;
    record_outline(data);
    record_steps(data);
    record_result(data);
}

// ******** Dynamic Page ********

function dynamic_page() {
    // **** Updating Page ****
    var last_time = '';  // For detecting update
    var first_time = ''; // For first time at a new macro;
    var steps_length = 0;
    return function(data, status) {
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
    function update_steps(data) {
        var crnt = data.steps.length;
        if (steps_length == crnt) {
            // When Step doesn't increase.
            var step = data.steps[crnt - 1];
            $('#' + step.time).html(make_step(step));
        }else {
            // When Step increases.
            for (var i = steps_length; i < crnt; i++) {
                var step = data.steps[i];
                $('.depth' + step.depth + ':last').append(make_step(step));
            }
            steps_length = i;
        }
        sticky_bottom('slow');
        record_status(data);
    }

    // **** Make Pages ****
    function mcr_end(data) {
        record_result(data);
        init_commands();
        stop_upd();
    }
    function record_first(data) {
        port = data.port;
        record_outline(data);
        if (data.status == 'end') {
            mcr_end(data);
        }else { //run
            start_upd('latest');
        }
        record_steps(data);
        steps_length = data.steps.length;
    }
    function record_update(data) {
        var stat = data.status;
        if (stat == 'end') {
            mcr_end(data);
            $('#record ul').empty();
            steps_length = 0;
        }else if (stat == 'query') {
            record_commands(data.option);
        }
        update_steps(data);
    }
}
// *** Ajax ***
function archive(tag) {
    $.getJSON('record_' + tag + '.json', static_page);
}
function update(tag) {
    var par = {dataType: 'json', ifModified: true, success: upd_record};
    tag = tag ? tag : 'latest';
    $.ajax('record_' + tag + '.json', par);
    blinking();
    remain_msg();
}
// ******** Direct Command ********
// *** Controls on Footer Bars ***
function dvctl_sel(obj) {
    var cmd = $('#nonstop :checkbox').prop('checked') ? 'nonstop' : 'interactive';
    dvctl(cmd);
    seldv(obj);
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
var upd_record = dynamic_page();
var start_time = ''; // For elapsed time
