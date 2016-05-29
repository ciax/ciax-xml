// Recommended Package: closure-linter
// fixjsstyle record.js
// ********* Steps **********
// step header section
function step_title(type) {
    html_rec.push('<span class="head ' + type + '">' + type + '</span>');
    html_rec.push('<span class="cmd">');
}
function step_label(step) {
    if (step.label) {html_rec.push(': ' + step.label);}
}
function step_cmd(step) {
    var ary = [];
    if (step.site) { ary.push(step.site); }
    if (step.args) { ary = ary.concat(step.args); }
    if (step.val) { ary.push(step.val); }
    if (ary.length > 0) {html_rec.push(': [' + ary.join(':') + ']');}
    html_rec.push('</span>');
}
// result section
function step_result(res) {
    if (res) {
        html_rec.push(' -> ');
        html_rec.push('<em class="res ' + res + '">' + res + '</em>');
    }
}
function step_action(step) {
    if (step.action) {
        html_rec.push(' <span class="action">(');
        html_rec.push(step.action);
        html_rec.push(')</span>');
    }
}
// elapsed time section
function step_time(step) {
    var now = new Date(step.time);
    var elps = ((now - start_time) / 1000).toFixed(2);
    html_rec.push('<span class="elps tail">[' + elps + ']</span>');
}
// waiting step
function step_meter(step, max) {
    html_rec.push(' <meter value="' + step.count / max * 100 + '" max="100"');
    if (step.retry) html_rec.push('low="70" high="99"');
    html_rec.push('>(' + step.count + '/' + max + ')</meter>');
}
function step_count(step) {
    if (step.count) {
        var max = step.retry || step.val;
        if (step.type != 'mcr') step_meter(step, max);
        html_rec.push('<span>(' + step.count + '/' + max + ')</span>');
        if (step.busy) html_rec.push(' -> <em class="res active">Busy</em>');
    }
}
// other steps
function step_exe(step) {
    html_rec.push('<h4>');
    step_title(step.type);
    step_label(step);
    step_cmd(step);
    step_count(step);
    step_result(step.result);
    step_action(step);
    step_time(step);
    html_rec.push('</h4>');
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
function cond_list(conds, type) {
    for (var k in conds) {
        var cond = conds[k];
        var res = cond.res;
        html_rec.push('<li>');
        html_rec.push('<var>' + cond.site + ':' + cond.var + '(' + cond.form + ')</var>');
        html_rec.push('<code>' + operator(cond.cmp, cond.cri) + '?</code>  ');
        if (type == 'goal' && res == false) res = 'warn';
        html_rec.push('<em class="' + res + '"> (' + cond.real + ')</em>');
        html_rec.push('</li>');
    }
}
function step_cond(step) {
    html_rec.push('<ul>');
    cond_list(step.conditions, step.type);
    html_rec.push('</ul>');
}
// Make Step Line
function make_step(step) {
    html_rec = ['<li>'];
    step_exe(step);
    if (step.conditions){
        step_cond(step)
    }else if (step.type == 'mcr'){
        html_rec.push('<ul class="depth' + (step.depth-0+1) +'"></ul>');
    }
    html_rec.push('</li>');
    return html_rec.join('');
}
// ********* Record **********
// Indent
function step_level(crnt) {
    while (crnt != depth) {
        if (crnt > depth) {
            html_rec.push('<ul>');
            depth += 1;
        }else {
            html_rec.push('</ul></li>');
            depth -= 1;
        }
    }
}
// Macro Body
function make_record(data) {
    start_time = new Date(data.start);
    $('#record')[0].innerHTML = '<ul class="depth1"></ul>';
    for (var j in data.steps) {
        var step = data.steps[j];
        $('.depth'+step.depth+':last').append(make_step(step));
    }
    depth = step_level(1);
    sticky_bottom('slow');
    html_rec = null;
}
// ********* Outline **********
// *** Static Display
function record_header(data) {
    $('#mcrcmd').text(data.label + ' [' + data.cid + ']');
    $('#date').text(new Date(data.id - 0));
}
function record_status(data) {
    replace('#status', data.status);
}
function record_result(data) {
    replace('#result', data.result);
    replace('#' + data.id + ' em', data.result);
    $('#total').text('[' + data.total_time + ']');
}
function record_commands(ary) {
    var sel = $('#query select')[0];
    if (sel) make_select(sel, ary);
}
// *** Initialize Page ***
function record_init(data) {
    record_header(data);
    record_status(data);
    $('#total').text('');
    replace('#result', '');
    port = data.port;
    if (data.status == 'end') {
        mcr_end(data);
    }else { //run
        start_upd();
    }
}
function record_update(data) {
    record_status(data);
    var stat = data.status;
    if (stat == 'end') {
        mcr_end(data);
    }else if (stat == 'query') {
        record_commands(data.option);
    }
}
// **** Update Page ****
function mcr_end(data) {
    record_result(data);
    init_select();
    stop_upd();
}
// **** Remote Control ****
function dvctl_nonstop() {
    if (itvl && !$('#nonstop :checkbox').prop('checked')) dvctl('interactive');
}
function dvctl_sel(obj) {
    var cmd = $('#nonstop :checkbox').prop('checked') ? 'nonstop' : 'interactive';
    dvctl(cmd);
    seldv(obj);
}
function dvctl_stop() {
    if (itvl) stop();
}
// ******** Make Pages ********
function dynamic_page(data) {
    make_record(data);
    if (first_time != data.id) { // Do only the first one for new macro
        first_time = data.id;
        record_init(data);
    }else if (data.time != last_time) { // Do every time for updated record
        if (last_time == last_upd) record_update(data);
        last_time = data.time;
    }else if (last_time != last_upd) { // Do only the first one of the stagnation
        last_upd = last_time;
        record_update(data);
    }
    blinking();
}
function static_page(data) {
    make_record(data);
    record_header(data);
    record_result(data);
    record_status(data);
}
// ******** HTML ********
function archive(tag) {
    depth = 1;
    $.getJSON('record_' + tag + '.json', static_page);
}
function update() {
    depth = 1;
    $.getJSON('record_latest.json', dynamic_page);
    remain_msg();
}
// Initial Commands
function init_select() {
    var slots = [];
    for (var i = 0; i <= 23; i++) { slots.push('slot' + i); }
    var ary = ['upd'];
    ary.push(['init', ['tinit', 'cinit']]);
    ary.push(['mos', ['start', 'load', 'store', 'fin', 'kapa', 'kapa1']]);
    ary.push(['slot', slots]);
    record_commands(ary);
}
function init_record_event() {
    height_adjust();
    set_acordion('#record');
    set_auto_release('#record');
}
function init_record() {
    init_record_event();
    update();
}
// Var setting
var html_rec;
var depth = 1;
var start_time = ''; // For elapsed time
var last_time = '';  // For detecting update
var last_upd = '';   // For prevent multiple update during no data changes
var first_time = ''; // For first time at a new macro;
var tag = 'latest';
var option = [];
var port;
