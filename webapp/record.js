// fixjsstyle record.js
function add_title(step) {
    all.push('<span class="head ' + step.type + '">' + step.type + '</span>');
}
function add_cmd(step) {
    var ary = [];
    if (step.site) { ary.push(step.site); }
    if (step.args) { ary.push(step.args[0]); }
    all.push(' <code>[' + ary.join(':') + ']</code>');
}
function add_result(step) {
    if (step.result) {
        all.push(' -> ');
        var cls = (step.result == 'failed') ? 'fail' : 'true';
        all.push('<em class="' + cls + '">' + step.result + '</em>');
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
    all.push('<h4>');
    add_title(step);
    add_cmd(step);
    add_count(step);
    add_result(step);
    all.push('</h4>');
}
function operator(ope, cri) {
    switch (ope) {
    case 'equal': return ('== ' + cri); break;
    case 'not' : return ('!= ' + cri); break;
    case 'match' : return ('=~ /' + cri + '/'); break;
    default:
    }
}
function step_cond(step) {
    var id = 'acdn' + all.length;
    all.push('<h4>');
    all.push('<a class="acdn" data-target="' + id + '">');
    add_title(step);
    all.push('</a>');
    add_count(step);
    add_result(step);
    all.push('</h4>');
    all.push('<dl id="' + id + '">');
    var conds = step.conditions;
    for (var k in conds) {
        var cond = conds[k];
        all.push('<dd>');
        all.push('<var>' + cond.site + ':' + cond.var + '(' + cond.form + ')</var>');
        all.push('<code>' + operator(cond.cmp, cond.cri) + '?</code>  ');
        all.push('<em class="cond ' + cond.res + '"> (' + cond.real + ')</em>');
        all.push('</dd>');
    }
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
        all.push('<h2>' + data.label + '</h2>');
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
    var target = $(this).data('target');
    $('#' + target).slideToggle();
}
function init() {
    update();
    acordion();
    setInterval(update, 1000);
}
var all = [];
var depth = 1;
$(document).ready(update);
$('.acdn').click(acordion);
