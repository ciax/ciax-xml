// Recommended Package: closure-linter
// fixjsstyle record.js
function add_title(type) {
    all.push('<span class="head ' + type + '">' + type + '</span>');
}
function add_label(step) {
    if (step.label) {all.push(':' + step.label);}
}
function add_cmd(step) {
    var ary = [];
    if (step.site) { ary.push(step.site); }
    if (step.args) { ary = ary.concat(step.args); }
    if (ary.length > 0) {all.push(': [' + ary.join(':') + ']');}
}
function mk_result(step) {
        var cls = (step.result == 'failed') ? 'false' : 'true';
        all.push('<em class="res ' + cls + '">' + step.result + '</em>');
}
function add_result(step) {
    if (step.result) {
        all.push(' -> ');
        mk_result(step);
    }
}
function add_time(step) {
    var now = new Date(step.time);
    var elps = ((now - start) / 1000).toFixed(2);
    all.push('<span class="elps">[' + elps + ']</span>');
}
function add_count(step) {
    if (step.count) {
        all.push(' (' + step.count);
        if (step.retry) { all.push('/' + step.retry); }
        all.push(')');
    }
}
function step_exe(step) {
    add_title(step.type);
    add_label(step);
    add_cmd(step);
    add_count(step);
    add_result(step);
    add_time(step);
}
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
        all.push('<dd>');
        all.push('<var>' + cond.site + ':' + cond.var + '(' + cond.form + ')</var>');
        all.push('<code>' + operator(cond.cmp, cond.cri) + '?</code>  ');
        if (type == 'goal' && res == false) { res = 'warn'; }
        all.push('<em class="' + res + '"> (' + cond.real + ')</em>');
        all.push('</dd>');
    }
}
function step_cond(step) {
    all.push('<dl class="cond"><dt>');
    add_title(step.type);
    add_count(step);
    add_result(step);
    add_time(step);
    all.push('</dt>');
    cond_list(step.conditions, step.type);
    all.push('</dl>');
}
function move_level(crnt) {
    while (crnt != depth) {
        if (crnt > depth) {
            all.push('<dd><dl>');
            depth += 1;
        }else {
            all.push('</dl></dd>');
            depth -= 1;
        }
    }
}
function make_step(step) {
    all.push('<dd>');
    if (step.conditions) {
        step_cond(step);
    }else {
        step_exe(step);
    }
    all.push('</dd>');
}
function make_header(data) {
    all.push('<h2>');
    add_title('mcr');
    add_label(data);
    all.push(' [' + data.cid + ']');
    all.push('<date>' + start + '</date>');
    all.push('</h2>');
}
function make_footer(data) {
    all.push('<h3>[');
    mk_result(data);
    all.push(']<span class="elps">[' + data.total_time + ']</span>');
    all.push('</h3>');
}
function update() {
    all = [];
    depth = 1;
    $.getJSON('record_latest.json', function(data) {
        start = new Date(data.start);
        make_header(data);
        all.push('<dl>');
        for (var j in data.steps) {
            var step = data.steps[j];
            move_level(step.depth);
            make_step(step);
        }
        depth = move_level(1);
        all.push('</dl>');
        make_footer(data);
        $('#output')[0].innerHTML = all.join('');
    });
}
function acordion() {
    $(this).next().slideToggle();
}
function init() {
    update();
    acordion();
    setInterval(update, 1000);
}
var all = [];
var depth = 1;
var start = '';
$(document).ready(update);
$('.cond dt').click(acordion);
