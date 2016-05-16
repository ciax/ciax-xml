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
// Macro Header and Footer
function record_header(data) {
    html_rec.push('<h2>');
    step_title('mcr');
    step_label(data);
    html_rec.push(' [' + data.cid + ']');
    html_rec.push('<date>' + start_time + '</date>');
    html_rec.push('</h2>');
    $('#mcrcmd').text(data.label + '[' + data.cid + ']');
}
function record_footer(data) {
    var res = data.result;
    html_rec.push('<h3 id="bottom">[');
    html_rec.push('<em class="res ' + res + '">' + res + '</em>');
    html_rec.push('](');
    html_rec.push(data.time + ')');
    if (data.total_time) {
        html_rec.push('<span class="elps">[' + data.total_time + ']</span>');
    }
    html_rec.push('</h3>');
}
// Macro Body
function make_record(data) {
    port = data.port;
    start_time = new Date(data.start);
    record_header(data);
    html_rec.push('<ul>');
    for (var j in data.steps) {
        var step = data.steps[j];
        step_level(step.depth);
        make_step(step);
    }
    depth = step_level(1);
    html_rec.push('</ul>');
    record_footer(data);
    $('#record')[0].innerHTML = html_rec.join('');
}
// ******* Page Footer *********
function make_select(ary) {
    var opt = ['<option>--select--</option>'];
    for (var i in ary) {
        opt.push('<option>' + ary[i] + '</option>');
    }
    $('#query select')[0].innerHTML = opt.join('');
}
// ** Stat **
function mk_stat(stat) {
    var str = '<span class="res ' + stat + '">' + stat + '</span>';
    $('#status')[0].innerHTML = str;
}
function make_footer(stat) {
    mk_stat(stat);
    if (stat == 'query') {
        make_select(option);
        blinking();
    }else if (stat == 'end') {
        clearInterval(itvl);
        set_acordion('#record');
        make_select(['cinit','start','fin']);
    }
}
// ******** HTML Page ********
function archive(tag) {
    html_rec = [];
    depth = 1;
    $.getJSON('record_' + tag + '.json', function(data) {
        make_record(data);
        set_acordion('#record', true);
        $('.footer').hide();
    });
}
function update() {
    html_rec = [];
    depth = 1;
    $.getJSON('record_latest.json', function(data) {
        mk_stat(data.status);
        if (data.time != last_time) {
            last_time = data.time;
            make_record(data);
        }else {
            make_footer(data.status);
        }
        height_adjust();
        sticky_bottom();
    });
}
// Var setting
var html_rec = [];
var depth = 1;
var start_time = '';
var last_time = '';
var tag = 'latest';
var option = [];
var port;
