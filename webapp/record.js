// fixjsstyle record.js
function step_mcr(step, all) {
    all.push('<p class="warn">' + step.type);
    all.push('[' + step.args[0] + ']');
    if(step.result) { all.push(' -> '+ step.result);}
    all.push('</p>');
}
function step_exe(step, all) {
    all.push('<p class="active">' + step.type);
    all.push('[' + step.site + ':' + step.args[0] + ']');
    if(step.result) { all.push(' -> '+ step.result);}
    all.push('</p>');
}
function step_sleep(step, all) {
    all.push('<p>' + step.type);
    all.push('(' + step.count + ')');
    if(step.result) { all.push(' -> '+ step.result);}
    all.push('</p>');
}
function step_upd(step, all) {
    all.push('<p class="normal">' + step.type);
    all.push(' [' + step.site + ']');
    all.push('</p>');
}
function operator(ope, cri) {
    switch (ope) {
    case 'equal': return ('== ' + cri); break;
    case 'not' : return ('!= ' + cri); break;
    case 'match' : return ('=~ /' + cri + '/'); break;
    default:
    }
}
function step_cond(step, all) {
    all.push('<dl>');
    all.push('<dt>' + step.type);
    if(step.count){
        all.push('(' + step.count + '/' + step.retry + ')');
    }
    all.push(' ->' + step.result + '</dt>');
    var conds = step.conditions;
    for (var k in conds) {
        var cond = conds[k];
        all.push('<dd>');
        all.push('<span class="stat">' + cond.site + ':' + cond.var + '(' + cond.form + ')</span>');
        all.push('<span>' + operator(cond.cmp, cond.cri) + '?</span>  ');
        all.push('<em class="cond ' + cond.res + '"> (' + cond.real + ')</em>')
        all.push('</dd>');
    }
    all.push('</dl>');
}
function move_level(all, crnt, depth) {
    while (crnt != depth) {
        if (crnt > depth) {
            all.push('<dd><dl>');
            depth += 1;
        }else {
            all.push('</dl></dd>');
            depth -= 1;
        }
    }
    return depth;
}
function make_step(step, all) {
    all.push('<dd>');
    if (step.type == 'mcr') {
        step_mcr(step, all);
    }else if (step.conditions) {
        step_cond(step, all);
    }else if (step.args) {
        step_exe(step, all);
    }else if (step.type == 'wait'){
        step_sleep(step, all);
    }else{
        step_upd(step, all);
    }
    all.push('</dd>');
}
function update() {
    $.getJSON('record_latest.json', function(data) {
        var all = [];
        var depth = 1;
        all.push('<h2>' + data.label + '</h2>');
        all.push('<dl>');
        for (var j in data.steps) {
            var step = data.steps[j];
            depth = move_level(all, step.depth, depth);
            make_step(step, all);
        }
        depth = move_level(all, 1, depth);
        all.push('</dl>');
        all.push('<h3>(' + data.result + ')</h3>');
        $('#output')[0].innerHTML = all.join('');
    });
}
function init() {
    update();
    setInterval(update, 1000);
}
$(document).ready(update);
