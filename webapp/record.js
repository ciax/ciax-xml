// fixjsstyle record.js
function step_mcr(step, all) {
    all.push('<p>' + step.type);
    all.push('(' + step.args[0] + ')' + step.depth + '</p>');
}
function step_cond(step, all) {
    all.push('<p>' + step.type + step.depth + '</p><ul>');
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
function move_level(all, crnt, depth) {
    while (crnt != depth) {
        if (crnt > depth) {
            all.push('<ul>');
            depth += 1;
        }else {
            all.push('</ul>');
            depth -= 1;
        }
    }
    return depth;
}
function make_step(step, all) {
    all.push('<li>');
    if (step.type == 'mcr') {
        step_mcr(step, all);
    }else if (step.conditions) {
        step_cond(step, all);
    }else {
        all.push('<p>' + step.type + ' (' + step.site + ')' + step.depth + '</p>');
    }
    all.push('</li>');
}
function update() {
    $.getJSON('record_latest.json', function(data) {
        var all = [];
        var depth = 0;
        all.push('<h2>' + data.label + '</h2>');
        for (var j in data.steps) {
            var step = data.steps[j];
            depth = move_level(all, step.depth, depth);
            make_step(step, all);
        }
        depth = move_level(all, 0, depth);
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
