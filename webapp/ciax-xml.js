//********* Shared **********
function replace(sel, str, cls) {
    return $(sel).text(str).attr('class', cls || str);
}
// ******* Animation *********
// Auto scroll. Check box with id:go_bottm is needed;
function sticky_bottom(speed) {
    if (!$('#scroll :checkbox').prop('checked')) return;
    var div = $('#record');
    div.animate({ scrollTop: div[0].scrollHeight},speed);
}
function auto_release() {
    var cr = $(this).scrollTop();
    if (cr < start_pos && !$('#record :animated')[0])
        $('#scroll :checkbox').prop('checked', false);
    start_pos = cr;
}
function set_auto_release(sel) {
    var div = $(sel);
    start_pos = div.scrollTop();
    div.on('mouseenter', function() {
        $(this).on('scroll', auto_release);
    });
    div.on('mouseleave', function() {
        $(this).off('scroll', auto_release);
    });
}
// Folding
function acordion(sel) {
    $(sel).next().slideToggle('slow', function() {
        sticky_bottom(0);
    });
}
function set_acordion(sel) {
    $(sel).on('click', 'h4', function() {
        acordion(this);
    });
    // All list will be folded when titie is clicked
    $(sel).parent().on('click', '.title', function() {
        acordion(sel + ' h4');
    });
}
// interactive mode
function blinking() {
    $('.query,.run,.busy').fadeOut(500, function() {$(this).fadeIn(500)});
}
// contents resize
function height_adjust() {
    var h = $(window).height();
    // sum height of children in .outline except .contents
    $('.outline').each(function() {
        $(this).children('div:not(".contents")').each(function() {
            h = h - $(this).height();
        });
        $(this).children('.contents').css('max-height', h - 100);
        sticky_bottom(0);
    });
}
// ******** Control by UDP ********
// dvctl with func when success
function dvctl(cmd, func) {
    var args = {port: port, cmd: cmd};
    //console.log('send=' + JSON.stringify(args));
    $.ajax('/json/dvctl-udp.php', {
        data: args,
        ifModified: true,
        cache: false,
        success: function(data) {
            //console.log('recv=' + JSON.stringify(data));
            replace('#msg', data.msg, data.msg.toLowerCase());
            if (func) func();
        },
        error: function(data) {
            //console.log('recv=' + JSON.stringify(data));
            stop_upd();
            replace('#msg', 'NO Response', 'error');
        }
    });
}
// With Confirmation
function exec(cmd, func) {
    if (confirm('EXEC?(' + cmd + ')')) {
        dvctl(cmd, func);
        return true;
    }else
        return false;
}
// Button/Check
function stop() {
    if (itvl) dvctl('interrupt');
}
function interactive() {
    var sel = $('#nonstop :checkbox');
    if (!(itvl && sel[0])) return;
    if (sel.prop('checked'))
        dvctl('nonstop');
    else
        dvctl('interactive');
}
// Select Command
function make_select(obj, ary) {
    var opt = ['<option>--select--</option>'];
    make_opt(opt, ary);
    obj.innerHTML = opt.join('');
    if (ary.length > 0) $('#msg').text('');

    function make_opt(opt, ary) {
        for (var i in ary) {
            if (Array.isArray(ary[i])) {
                // Grouping
                opt.push('<optgroup label="' + ary[i][0] + '">');
                make_opt(opt, ary[i][1]);
                opt.push('</optgroup>');
            }else {
                opt.push('<option>' + ary[i] + '</option>');
            }
        }
    }
}
function get_select(obj) {
    var cmd = obj.options[obj.selectedIndex].value;
    if (cmd == '--select--') return;
    return cmd;
}
function seldv(obj) {
    var cmd = get_select(obj);
    if (cmd) exec(cmd);
}
// ********* Ajax *********
function ajax_static(url, func) {
    $.ajax(url, { ifModified: false, cache: true, success: func});
}
// func1 for updated, func2 for no changes
function ajax_update(url, func1, func2) {
    $.ajax(url, { ifModified: true, cache: false, success: func1, error: func2});
}
// ********* Page Update *********
// Control Part/Shared with ciax-xml.js
function stop_upd() {
    if (!itvl) return;
    clearInterval(itvl);
    itvl = null;
}
function start_upd(func) {
    if (itvl || !func) return;
    itvl = setInterval(func, 1000);
    return true;
}
var itvl;
var port;
var start_pos = 0;
$(window).on('resize', height_adjust);
// ifModified option makes error in FireFox (not Chrome).
// JSON will be loaded as html if no update at getJSON().
$.ajaxSetup({ mimeType: 'json', cahce: false});
