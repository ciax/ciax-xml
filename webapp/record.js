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
function step_query(step) {
    if (step.option) {
        option = step.option;
        html_rec.push(' <span class="query">[');
        html_rec.push(step.option.join('/'));
        html_rec.push(']</span> ');
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
    step_query(step);
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
    html_rec.push('</ul></li>');
}
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
// Make Step Line
function make_step(step) {
    html_rec.push('<li>');
    step_exe(step);
    if (step.conditions) {
        step_cond(step);
    }else if (step.type != 'mcr') {
        html_rec.push('</li>');
    }
}
// ********* Record **********
// Macro Body
function make_record(data) {
    start_time = new Date(data.start);
    html_rec.push('<ul>');
    for (var j in data.steps) {
        var step = data.steps[j];
        step_level(step.depth);
        make_step(step);
    }
    depth = step_level(1);
    html_rec.push('</ul>');
    $('#record')[0].innerHTML = html_rec.join('');
    height_adjust();
    sticky_bottom();
}
// ********* Outline **********
// *** Static Display
function record_header(data) {
    $('#mcrcmd').text(data.label + ' [' + data.cid + ']');
    $('#date').text(new Date(data.id - 0));
}
// *** Result/Footer ***
function replace_status(stat) {
    $('#status').text(stat);
    $('#status').attr('class', 'res ' + stat);
}
function record_result(data) {
    $('#result').text(data.result);
    $('#result').attr('class', 'res ' + data.result);
    $('#total').text('[' + data.total_time + ']');
}
// *** Initialize Page ***
function record_init(data) {
    record_header(data);
    $('#total').text('');
    $('#result').text('');
    port = data.port;
    if (data.status == 'end') {
        mcr_end(data);
    }else { //run
        mcr_start(data);
    }
}
function record_select(ary) {
    var sel = $('#query select')[0];
    if (sel) make_select(sel, ary);
}
function record_status(data) {
    var stat = data.status;
    if (stat == 'end') {
        mcr_end(data);
    }else if (stat == 'query') {
        replace_status(stat);
        record_select(option);
    }else {
        replace_status(stat); //run
    }
}
// **** Update Page ****
function mcr_start(data) {
    start_upd();
    replace_status('run');
    $('#scroll').show();
    $('#scroll :checkbox').prop('checked', true);
}
function mcr_end(data) {
    replace_status('end')
    record_result(data);
    set_acordion('#record h4');
    record_select(['upd', 'tinit', 'cinit', 'start', 'load', 'store', 'fin']);
    stop_upd();
    $('#scroll').hide();
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
// ******** HTML ********
function archive(tag) {
    html_rec = [];
    depth = 1;
    $.getJSON('record_' + tag + '.json', function(data) {
        make_record(data);
        record_header(data);
        record_result(data);
        set_acordion('#record h4');
    });
}
function update() {
    html_rec = [];
    depth = 1;
    $.getJSON('record_latest.json', function(data) {
        make_record(data);
        if (first_time != data.id) { // Do only the first one for new macro
            first_time = data.id;
            record_init(data);
        }else if (data.time != last_time) { // Do every time for updated record
            if (last_time == last_upd) record_status(data);
            last_time = data.time;
        }else if (last_time != last_upd) { // Do only the first one of the stagnation
            last_upd = last_time;
            record_status(data);
        }
        blinking();
    });
    remain_msg();
}
function init() {
    update();
}
// Var setting
var html_rec = [];
var depth = 1;
var start_time = ''; // For elapsed time
var last_time = '';  // For detecting update
var last_upd = '';   // For prevent multiple update during no data changes
var first_time = ''; // For first time at a new macro;
var tag = 'latest';
var option = [];
var port;

