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
function mk_result(step) {
    var cls = 'true';
    if (step.result.match(/failed|error/)) {
        cls = 'false';
    }else if (step.result == 'busy') {
        cls = 'active';
    }
    all.push('<em class="res ' + cls + '">' + step.result + '</em>');
}
function step_result(step) {
    if (step.result) {
        all.push(' -> ');
        mk_result(step);
    }
}
function step_action(step) {
    if (step.action) {
        all.push('<ul' + hide + '>');
        all.push('<li><span class="action">(');
        all.push(step.action);
        all.push(')</span></li></ul>');
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
    step_result(step);
    step_time(step);
    all.push('</h4>');
    step_action(step);
    set_query(step);
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
    all.push('<ul' + hide + '>');
    cond_list(step.conditions, step.type);
    all.push('</ul></li>');
}
// Indent
function step_level(crnt) {
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
    all.push('<h3 id="bottom">[');
    mk_result(data);
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
// ********* External Control **********
// CGI
function dvctl(cmd) {
    if (!confirm('EXEC?(' + cmd + ')')) return;
    $.post(
        '/json/dvctl-udp.php',
        {port: port, cmd: cmd},
        function(data) {
            $('#msg').text($.parseJSON(data).msg);
        }
    );
    update();
}
// ******* Page Footer *********
// auto scroll
function set_query(step) {
    if (step.option) {
        for (var k in step.option) {
            $('#' + step.option[k]).show();
        }
    }else {
        $('button').hide();
    }
}// ******* Animation *********
function sticky_bottom() {
    var div = $('#record');
    var toggle = $('#go_bottom');
    if (toggle.prop('checked')) {
        manual = false;
        div.animate({ scrollTop: div[0].scrollHeight},'slow', function() {
            manual = true;
        });
        div.on('scroll', function() {
            if (manual) {toggle.prop('checked', false);}
        });
    }
}
// Folding
function acordion() {
    $('h4').on('click', function() {
        $(this).next().slideToggle();
    });
}
// interactive mode
function blinking() {
    $('.qry').fadeOut(500, function() {$(this).fadeIn(500)});
}
// ******** HTML Page ********
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
        if (data.time != last_time) {
            last_time = data.time;
            make_record(data);
        }
        sticky_bottom();
        blinking();
    });
}
// ********* Page Update *********
// regular updating
function stop() {
    clearInterval(itvl);
    scroll = false;
}
// Control Part/Shared with ciax-xml.js
function init() {
    $.ajaxSetup({ cache: false});
    $('button').hide();
    update();
    setInterval(update, 1000);
}
// Var setting
var all = [];
var depth = 1;
var start_time = '';
var last_time = '';
var tag = 'latest';
var hide = '';
var manual = false;
var port = '';
//$(document).ready(init);
