// Need var: Type,Site
function step_mcr(step, all) {
    all.push('<p>' + step.type);
    all.push('('+ step.args[0] + ')'+ step.depth + '</p><ul>');
    return step.depth;
}
function step_cond(step, all) {
    all.push('<p>' + step.type + '</p><ul>');
    var conds = step.conditions;
    for (var k in conds) {
        var cond = conds[k];
        all.push('<li><p>');
        all.push(cond.site + ':' + cond.var);
        all.push(' (' + cond.res + ')');
        all.push('</p></li>');
    }
    all.push('</ul>');
}
function take_back(step, all, depth) {
    while (step.depth <= depth) {
        all.push('</ul>');
        depth -= 1;
    }
    return depth;
}
function make_step(step, all, depth) {
    all.push('<li>');
    if (step.type == 'mcr') {
        depth = step_mcr(step, all);
    }else if (step.conditions) {
        step_cond(step, all);
    }else {
        all.push('<p>' + step.type + ' (' + step.site + ')</p>');
    }
    all.push('</li>');
    return depth;
}
function update() {
    $.getJSON('record_latest.json', function(data) {
        var all = [];
        var depth = 0;
        all.push('<h2>' + data.label + '</h2>');
        all.push('<ul>');
        for (var j in data.steps) {
            var step = data.steps[j];
            depth = take_back(step, all, depth);
            depth = make_step(step, all, depth);
        }
        depth = take_back(0, depth, all);
        all.push('<h3>(' + data.result + ')</h3>');
        $('#output')[0].innerHTML = all.join('');
    });
}
function init() {
    update();
    setInterval(update, 1000);
}
//$(document).ready(init);
$(document).ready(update);
