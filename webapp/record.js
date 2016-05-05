// fixjsstyle record.js
function add_title(step) {
    all.push('<span class="head ' + step.type + '">' + step.type + '</span>');
}
function add_cmd(step) {
    if (step.label) {all.push(':' + step.label);}
    var ary = [];
    if (step.site) { ary.push(step.site); }
    if (step.args) { ary.push(step.args[0]); }
    if (ary.length > 0) {all.push(': [' + ary.join(':') + ']');}
}
function add_result(step) {
    if (step.result) {
        all.push(' -> ');
        var cls = (step.result == 'failed') ? 'false' : 'true';
        all.push('<em class="res ' + cls + '">' + step.result + '</em>');
    }
}
function add_count(step) {
    if (step.count) {
        all.push(' (' + step.count);
        if (step.retry) { all.push('/' + step.retry); }
        all.push(')');
    }
}
function step_exe(step) {
    add_title(step);
    add_cmd(step);
    add_count(step);
    add_result(step);
}
function operator(ope, cri) {
    switch (ope) {
    case 'equal': return ('== ' + cri); break;
    case 'not' : return ('!= ' + cri); break;
    case 'match' : return ('=~ /' + cri + '/'); break;
    default:
    }
}
function cond_list(conds, type){
    for (var k in conds) {
        var cond = conds[k];
        var res = cond.res;
        all.push('<dd>');
        all.push('<var>' + cond.site + ':' + cond.var + '(' + cond.form + ')</var>');
        all.push('<code>' + operator(cond.cmp, cond.cri) + '?</code>  ');
        if (type == 'goal' && res == false) { res = 'warn'; }
        all.push('<em"' + res + '"> (' + cond.real + ')</em>');
        all.push('</dd>');
    }
}
function step_cond(step) {
    all.push('<dl class="cond"><dt>');
    add_title(step);
    add_count(step);
    add_result(step);
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
function update() {
    all = [];
    depth = 1;
    $.getJSON('record_latest.json', function(data) {
        all.push('<h2>' + data.label + '(' + data.cid + ')</h2>');
        all.push('<dl>');
        for (var j in data.steps) {
            var step = data.steps[j];
            move_level(step.depth);
            make_step(step);
        }
        depth = move_level(1);
        all.push('</dl>');
        all.push('<h4>(' + data.result + ')</h4>');
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
$(document).ready(update);
$('.cond dt').click(acordion);
