// Recommended Package: closure-linter
// fixjsstyle record.js
// step header
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
// result section
function mk_result(step) {
    var cls = 'true';
    if (step.result.match(/failed|error/)) {
        cls = 'false';
    }else if (step.result == 'busy') {
        cls = 'active';
    }
    all.push('<em class="res ' + cls + '">' + step.result + '</em>');
}
function add_result(step) {
    if (step.result) {
        all.push(' -> ');
        mk_result(step);
    }
}
// elapsed time section
function add_time(step) {
    var now = new Date(step.time);
    var elps = ((now - start_time) / 1000).toFixed(2);
    all.push('<span class="elps">[' + elps + ']</span>');
}
// waiting step
function add_meter(step, max) {
    all.push(' <meter value="' + step.count / max * 100 + '" max="100"');
    if (step.retry) { all.push('low="70" high="99"');}
    all.push('>(' + step.count + '/' + max + ')</meter>');
}
function add_count(step) {
    if (step.count) {
        var max = step.retry || step.val;
        add_meter(step, max);
        all.push('<span>(' + step.count + '/' + max + ')</span>');
        if (step.busy) { all.push(' -> <em class="res active">Busy</em>');}
    }
}
// other steps
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
    step_exe(step);
    all.push('<ul' + hide + '>');
    cond_list(step.conditions, step.type);
    all.push('</ul>');
}
// indent
function move_level(crnt) {
    while (crnt != depth) {
        if (crnt > depth) {
            all.push('<ul' + hide + '>');
            depth += 1;
        }else {
            all.push('</ul></li>');
            depth -= 1;
        }
    }
}
function make_step(step) {
    all.push('<li>');
    if (step.conditions) {
        step_cond(step);
        all.push('</li>');
    }else if (step.type == 'mcr') {
        step_exe(step);
    }else {
        step_exe(step);
        all.push('</li>');
    }
}
// make page
function make_header(data) {
    all.push('<h2>');
    add_title('mcr');
    add_label(data);
    all.push(' [' + data.cid + ']');
    all.push('<date>' + start_time + '</date>');
    all.push('</h2>');
}
function make_footer(data) {
    all.push('<h3 id="bottom">[');
    mk_result(data);
    all.push(']');
    if (data.total_time) {
        all.push('<span class="elps">[' + data.total_time + ']</span>');
    }
    all.push('</h3>');
}
function make_record(data) {
    start_time = new Date(data.start);
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
}
// decoration
function acordion() {
    $('h4').on('click', function() {
        $(this).next().slideToggle();
    });
}
function scrolling() {
    var target = $('#bottom');
    $(window).scrollTop(target.offset().top);
}
function check_bottom() {
    // not correct, because of acordion
    $(window).bind('scroll', function() {
        var scrollHeight = $(document).height();
        var scrollPosition = $(window).height() + $(window).scrollTop();
        scroll = (scrollHeight - scrollPosition);
    });
}
// make html
function static() {
    hide = ' style="display:none;"';
    $.getJSON('record_' + tag + '.json', function(data) {
        make_record(data);
        acordion();
    });
}
function update() {
    all = [];
    depth = 1;
    $.getJSON('record_latest.json', function(data) {
        make_record(data);
        if (scroll) { scrolling();}
        if (data.status == 'end') { stop; }
    });
}
// regular updating
function stop() {
    clearInterval(itvl);
    scroll = false;
}
function init() {
    update();
    check_bottom();
    itvl = setInterval(update, 1000);
}
var all = [];
var depth = 1;
var start_time = '';
var itvl;
var tag = 'latest';
var scroll = false;
var hide = '';
//need tag setting
