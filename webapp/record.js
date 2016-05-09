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
    var cls = step.result.match(/failed|error/) ? 'false' : 'true';
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
        var max = step.retry || step.val;
        all.push('<span>(' + step.count + '/' + max + ')</span>');
        all.push('<meter value="' + step.count / max * 100 + '" max="100"');
        if (step.retry) { all.push('low="60" high="80"');}
        all.push('/>');
    }
}
function step_exe(step) {
    all.push('<h4>');
    add_title(step.type);
    add_label(step);
    add_cmd(step);
    add_count(step);
    add_result(step);
    add_time(step);
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
    step_exe(step);
    all.push('<ul style="display:none;">');
    cond_list(step.conditions, step.type);
    all.push('</ul>');
}
function move_level(crnt) {
    while (crnt != depth) {
        if (crnt > depth) {
            all.push('<ul>');
            depth += 1;
        }else {
            all.push('</ul>');
            depth -= 1;
        }
    }
}
function make_step(step) {
    all.push('<li>');
    if (step.conditions) {
        step_cond(step);
    }else {
        step_exe(step);
    }
    all.push('</li>');
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
function acordion() {
    $('h4').on('click', function() {
        $(this).next().slideToggle();
    });
}
function update() {
    all = [];
    depth = 1;
    var tag= Tag ? Tag : 'latest';
    $.getJSON('record_' + tag + '.json', function(data) {
        start = new Date(data.start);
        make_header(data);
        all.push('<ul>');
        for (var j in data.steps) {
            var step = data.steps[j];
            move_level(step.depth);
            make_step(step);
        }
        depth = move_level(1);
        all.push('</ul>');
        make_footer(data);
        $('#output')[0].innerHTML = all.join('');
        if (data.status == 'end') { clearInterval(itvl);}
        acordion();
    });
}
function init() {
    update();
    itvl = setInterval(update, 1000);
}
var all = [];
var depth = 1;
var start = '';
var itvl;
$(document).ready(init);
