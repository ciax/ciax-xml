// Recommended Package: closure-linter
// fixjsstyle record.js
// ********* Steps **********
// step header section
function make_step(step) {
    function _title() {
        var type = step.type;
        var ary = [];
        html.push('<span title="' + JSON.stringify(step).replace(/"/g, "'"));
        html.push('" class="head ' + type + '">' + type + '</span>');
        html.push('<span class="cmd"');
        if (step.site) {
            ary.push(step.site);
            html.push(_devlink(step.site));
        }
        html.push('>');
        if (step.args) { ary = ary.concat(step.args); }
        if (step.val) { ary.push(step.val); }
        if (step.label) html.push(': ' + step.label);
        if (ary.length > 0) {html.push(': [' + ary.join(':') + ']');}
        html.push('</span>');
    }
    // result section
    function _result() {
        var res = step.result;
        if (!res || res == 'busy') return;
        html.push(' -> ');
        html.push('<em class="' + res + '">' + res + '</em>');
    }
    function _action() {
        if (!step.action) return;
        html.push(' <span class="action">(');
        html.push(step.action);
        html.push(')</span>');
    }
    // elapsed time section
    function _time() {
        var crnt = new Date(step.time);
        var elps = ((crnt - start_time) / 1000).toFixed(2);
        html.push('<span class="elps tail" title="' + crnt.toTimeString() + '">[');
        html.push(elps + ']</span>');
    }
    // waiting step
    function _meter(max) {
        html.push(' <meter value="' + step.count / max * 100 + '" max="100"');
        if (step.retry) html.push('low="70" high="99"');
        html.push('>(' + step.count + '/' + max + ')</meter>');
    }
    function _count() {
        if (!step.count) return;
        var max = step.retry || step.val;
        if (step.type != 'mcr') _meter(max);
        html.push('<span>(' + step.count + '/' + max + ')</span>');
        if (step.busy) html.push(' -> <em class="active">Busy</em>');
    }
    // other steps
    function _header(attr) {
        html.push('<h4>');
        _title();
        _count();
        _result();
        _action();
        _time();
        html.push('</h4>');
    }

    // condition step
    function _operator(ope, cri) {
        switch (ope) {
        case 'equal': return ('== ' + cri); break;
        case 'not' : return ('!= ' + cri); break;
        case 'match' : return ('=~ /' + cri + '/'); break;
        case 'unmatch' : return ('!~ /' + cri + '/'); break;
        default:
        }
    }

    // External info
    function _devlink(site) {
        return ('onclick="open_table(\'' + site + '\');"');
    }
    function _graphlink(site, vid, time) {
        return ('onclick="open_graph(\'' + site + '\',\'' + vid + '\',\'' + time + '\');"');
    }

    function _conditions() {
        if (!step.conditions) return;
        html.push('<ul>');
        $.each(step.conditions, function(k, cond) {
            var res = cond.res;
            html.push('<li>');
            html.push('<var ' + _devlink(cond.site) + '>');
            html.push(cond.site + ':' + cond.var);
            html.push('(' + cond.form + ')</var>');
            html.push('<code>' + _operator(cond.cmp, cond.cri) + '?</code>  ');
            if (step.type == 'goal' && res == false) res = 'warn';
            html.push('<span class="' + res + '" ');
            html.push(_graphlink(cond.site, cond.var, step.time));
            html.push('> (' + cond.real + ')</span>');
            html.push('</li>');
        });
        html.push('</ul>');
        return true;
    }
    function _sub_mcr() {
        if (step.type != 'mcr') return;
        html.push('<ul class="depth' + (step.depth - 0 + 1) + '"></ul>');
    }

    var html = ['<li'];
    if (step.type != 'mcr') html.push(' class="step"');
    html.push('>');
    _header();
    _conditions() || _sub_mcr();
    html.push('</li>');
    return html.join('');
}
// ********* Outline **********
// *** Display on the Bars ***
function record_outline(data) { // Do at the first
    $('#mcrcmd').text(data.label + ' [' + data.cid + ']');
    $('#date').text(new Date(data.id - 0)).attr('title', data.id);
    $('#total').text('');
    $('#query').empty();
    $('#stop').hide();
    replace('#result', '');
    record_page(data);
}
// Macro Body
function record_page(data) {
    start_time = new Date(data.start); // empty when ready
    $('#record ul').empty();
    $.each(data.steps, function(i, step) {
        $('#record .depth' + step.depth + ':last').append(make_step(step));
    });
    sticky_bottom('slow');
    record_status(data);
}
function record_status(data) {
    replace('#status', data.status);
}
function record_result(data) { // Do at the end
    replace('#result', data.result);
    replace('#' + data.id + ' em', data.result);
    var last = new Date(data.time);
    $('#total').text('[' + data.total_time + ']').attr('title', last.toTimeString());
}

// ******** Dynamic Page ********
function dynamic_page() {
    // Update Command Selector
    function _init_commands() {
        ajax_static('/json/mcr_conf.json', function(data) {
            if (!port) port = data.port;
            make_select('select#command', data.commands);
        });
    }
    // Update Query Radio Button
    function _make_query(data) {
        var sel = $('#query')[0];
        if (!sel) return;
        if (data.status == 'query') {
            var cmdary = data.option.map(function(cmd) {
                return ([cmd, data.id]);
            });
            make_radio(sel, cmdary);
        }else {
            $('#query').empty();
        }
    }
    // Update Content of Steps (When JSON is updated)
    function _append_step(data) {
        // When Step increases.
        for (var i = steps_length; i < data.steps.length; i++) {
            var step = data.steps[i];
            $('.depth' + step.depth + ':last').append(make_step(step));
        }
        steps_length = i;
        sticky_bottom('slow');
        record_status(data);
    }
    function _update_step(data) {
        var crnt = data.steps.length;
        if (steps_length == crnt) {
            // When Step doesn't increase.
            var step = data.steps[crnt - 1];
            // Update Step
            $('.step:last').html(make_step(step));
            suspend = true;
        }else if (suspend) {
            // Refresh All Page at resume
            record_page(data);
            steps_length = crnt;
            suspend = false;
        }else {
            // Add Step
            _append_step(data);
        }
    }

    // **** Regular update on/off ****
    function _mcr_end(data) {
        if (data.status != 'end') return;
        record_page(data);
        record_result(data);
        _init_commands();
        $('#msg').text('');
        $('#query').empty();
        $('#stop').fadeOut(1000);
        delete upd_list.record;
        return true;
    }
    function _mcr_start() {
        if (upd_list.record) return;
        upd_list.record = update_record;
        set_sticky_bottom();
        interactive();
        $('#stop').show();
    }

    // **** Make Pages ****
    function _first_page(data) {
        record_outline(data); // Make record one time
        if (_mcr_end(data)) return;
        _make_query(data);
        _mcr_start(update_record);
        steps_length = data.steps.length;
    }
    function _next_page(data) {
        if (_mcr_end(data)) return;
        _make_query(data);
        _update_step(data); // Make record one by one
    }
    function _upd_page(data, status) {
        //console.log(status);
        //if (data) console.log(data.status+data.time);
        if (status != 'success') return;
        if (first_time != data.id) { // Do only the first one for new macro
            port = data.port;
            _first_page(data);
            first_time = data.id;
        }else if (data.time != last_time) { // Do every time for updated record
            //console.log('updated');
            _next_page(data);
            last_time = data.time;
        }
    }
    // **** Updating Page ****
    var last_time = '';  // For detecting update
    var first_time = ''; // For first time at a new macro;
    var steps_length = 0;
    var suspend = false;
    return function(tag) { // To be update
        tag = tag ? tag : 'latest';
        ajax_record(tag, _upd_page, function() { suspend = true;});
        blinking();
    }
}
// ******** Static Page *********
function static_page(data, status) {
    if (status != 'success') return;
    record_outline(data);
    record_result(data);
}

// ******** Ajax ********
// func1 for updated, func2 for no changes
function ajax_record(tag, func1, func2) {
    tag = tag ? tag : 'latest';
    ajax_update('record_' + tag + '.json', func1, func2);
}
function archive(tag) {
    // Read whether src is updated or not
    tag = tag ? tag : 'latest';
    ajax_static('record_' + tag + '.json', static_page);
}

// ******** Command ********
function selmcr(dom) {
    var cmd = get_select(dom);
    if (!cmd) return;
    exec(cmd, function() {
        // Do after exec if success
        make_select(dom, []);
        update_record();
    });
}

// ******** Init Page ********
init_list.push(function() {
    height_adjust();
    set_acordion('#record');
    set_auto_release('#record');
    update_record();
    $('#query').on('change', 'input[name="query"]:radio', function() {
        exec($(this).val(), function() {$('#query').empty(); });
    });
});
// Var setting
var update_record = dynamic_page();
var start_time; // For elapsed time
