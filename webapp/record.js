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
    html_rec.push('<span class="elps">[' + elps + ']</span>');
}
// waiting step
function step_meter(step, max) {
    html_rec.push(' <meter value="' + step.count / max * 100 + '" max="100"');
    if (step.retry) { html_rec.push('low="70" high="99"');}
    html_rec.push('>(' + step.count + '/' + max + ')</meter>');
}
function step_count(step) {
    if (step.count) {
        var max = step.retry || step.val;
        if (step.type != 'mcr') { step_meter(step, max); }
        html_rec.push('<span>(' + step.count + '/' + max + ')</span>');
        if (step.busy) { html_rec.push(' -> <em class="res active">Busy</em>');}
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
        if (type == 'goal' && res == false) { res = 'warn'; }
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
    port = data.port;
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
}
// Macro Header and Footer
function record_header(data) {
    $('#mcrcmd').text(data.label + ' [' + data.cid + ']');
    $('#date').text(start_time);
}
// ******* Page Footer *********
function record_footer(data) {
    mk_res('#status',data.status);
    mk_res('#result',data.result);
    if (data.total_time) {
        $('#total').text(data.total_time);
    }
}
function make_select(ary) {
    var opt = ['<option>--select--</option>'];
    for (var i in ary) {
        opt.push('<option>' + ary[i] + '</option>');
    }
    $('#query select')[0].innerHTML = opt.join('');
}
// ** Stat **
function mk_res(sel, stat) {
    $(sel).text(stat);
    $(sel).attr('class','res ' + stat);
}
function make_footer(stat) {
    mk_res('#status', stat);
    if (stat == 'query') {
        make_select(option);
    }else if (stat == 'end') {
        mcr_end();
    }
}
// ******** HTML Page ********
function archive(tag) {
    html_rec = [];
    depth = 1;
    $.getJSON('record_' + tag + '.json', function(data) {
        make_record(data);
        record_header(data);
        record_footer(data);
        set_acordion('#record h4', true);
    });
}
function update() {
    html_rec = [];
    depth = 1;
    $.getJSON('record_latest.json', function(data) {
        record_header(data);
        record_footer(data);
        if (data.time != last_time) {
            last_time = data.time;
            make_record(data);
            height_adjust();
            sticky_bottom();
        }else if (last_time != last_upd) {
            make_footer(data.status);
            last_upd = last_time;
        }
        blinking();
    });
}
function mcr_end(){
    stop_upd();
    set_acordion('#record h4');
    make_select(['cinit', 'start', 'fin']);
    $('#status').hide();
    $('#scroll').hide();
    $('#msg').hide();
    $('#total').show();
    $('#result').show();
}
function init(){
    $('#status').show();
    $('#scroll').show();
    $('#msg').show();
    $('#total').hide();
    $('#result').hide();
    start_upd();
}
// Var setting
var html_rec = [];
var depth = 1;
var start_time = '';
var last_time = '';
var last_upd = '';
var tag = 'latest';
var option = [];
var port;
