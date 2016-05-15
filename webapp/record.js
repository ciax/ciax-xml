// Recommended Package: closure-linter
// fixjsstyle record.js
// ********* Steps **********
// step header section
function step_title(type) {
    all.push('<span class="head ' + type + '">' + type + '</span>');
    all.push('<span class="cmd">');
}
function step_label(step) {
    if (step.label) {all.push(': ' + step.label);}
}
function step_cmd(step) {
    var ary = [];
    if (step.site) { ary.push(step.site); }
    if (step.args) { ary = ary.concat(step.args); }
    if (ary.length > 0) {all.push(': [' + ary.join(':') + ']');}
    all.push('</span>');
}
// result section
function step_result(res) {
    if (res) {
        all.push(' -> ');
        all.push('<em class="res ' + res + '">' + res + '</em>');
    }
}
function step_query(step) {
    if (step.option) {
        option = step.option;
        all.push(' <span class="query">[');
        all.push(step.option.join('/'));
        all.push(']</span> ');
    }
}
function step_action(step) {
    if (step.action) {
        all.push(' <span class="action">(');
        all.push(step.action);
        all.push(')</span>');
    }
}
// elapsed time section
function step_time(step) {
    var now = new Date(step.time);
    var elps = ((now - start_time) / 1000).toFixed(2);
    all.push('<span class="elps">[' + elps + ']</span>');
}
// waiting step
function step_meter(step, max) {
    all.push(' <meter value="' + step.count / max * 100 + '" max="100"');
    if (step.retry) { all.push('low="70" high="99"');}
    all.push('>(' + step.count + '/' + max + ')</meter>');
}
function step_count(step) {
    if (step.count) {
        var max = step.retry || step.val;
        if (step.type != 'mcr') { step_meter(step, max); }
        all.push('<span>(' + step.count + '/' + max + ')</span>');
        if (step.busy) { all.push(' -> <em class="res active">Busy</em>');}
    }
}
// other steps
function step_exe(step) {
    all.push('<h4>');
    step_title(step.type);
    step_label(step);
    step_cmd(step);
    step_count(step);
    step_result(step.result);
    step_query(step);
    step_action(step);
    step_time(step);
    all.push('</h4>');
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
        all.push('<li>');
        all.push('<var>' + cond.site + ':' + cond.var + '(' + cond.form + ')</var>');
        all.push('<code>' + operator(cond.cmp, cond.cri) + '?</code>  ');
        if (type == 'goal' && res == false) { res = 'warn'; }
        all.push('<em class="' + res + '"> (' + cond.real + ')</em>');
        all.push('</li>');
    }
}
function step_cond(step) {
    all.push('<ul>');
    cond_list(step.conditions, step.type);
    all.push('</ul></li>');
}
// Indent
function step_level(crnt) {
    while (crnt != depth) {
        if (crnt > depth) {
            all.push('<ul>');
            depth += 1;
        }else {
            all.push('</ul></li>');
            depth -= 1;
        }
    }
}
// Make Step Line
function make_step(step) {
    all.push('<li>');
    step_exe(step);
    if (step.conditions) {
        step_cond(step);
    }else if (step.type != 'mcr') {
        all.push('</li>');
    }
}
// ********* Record **********
// Macro Header and Footer
function record_header(data) {
    all.push('<h2>');
    step_title('mcr');
    step_label(data);
    all.push(' [' + data.cid + ']');
    all.push('<date>' + start_time + '</date>');
    all.push('</h2>');
    $('#mcrcmd').text(data.label + '[' + data.cid + ']');
}
function record_footer(data) {
    var res = data.result;
    all.push('<h3 id="bottom">[');
    all.push('<em class="res ' + res + '">' + res + '</em>');
    all.push('](');
    all.push(data.time + ')');
    if (data.total_time) {
        all.push('<span class="elps">[' + data.total_time + ']</span>');
    }
    all.push('</h3>');
}
// Macro Body
function make_record(data) {
    port = data.port;
    start_time = new Date(data.start);
    record_header(data);
    all.push('<ul>');
    for (var j in data.steps) {
        var step = data.steps[j];
        step_level(step.depth);
        make_step(step);
    }
    depth = step_level(1);
    all.push('</ul>');
    record_footer(data);
    $('#record')[0].innerHTML = all.join('');
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
        acordion();
        make_select(['cinit']);
    }
}
// ******** HTML Page ********
function archive(tag) {
    $.getJSON('record_' + tag + '.json', function(data) {
        make_record(data);
        acordion(true);
        $('.footer').hide();
    });
}
function update() {
    all = [];
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
var all = [];
var depth = 1;
var start_time = '';
var last_time = '';
var tag = 'latest';
var option = [];
var port;
//$(document).ready(init);
