//********* Shared **********
function replace(sel, str, cls) {
    $(sel).text(str).attr('class', 'res ' + (cls || str));
}
// ******* Animation *********
// Auto scroll. Check box with id:go_bottm is needed;
function auto_release() {
    var cr = $(this).scrollTop();
    if (cr < start_pos && !acdon)
        $('#scroll :checkbox').prop('checked', false);
    start_pos = cr;
}
function set_sticky_bottom() {
    start_pos = $('#record').scrollTop();
    $('#record').hover(function() {
        $(this).bind('scroll', auto_release);
    },function() {
        $(this).unbind('scroll', auto_release);
    });
}
function sticky_bottom(speed) {
    if (!$('#scroll :checkbox').prop('checked')) return;
    var div = $('#record');
    div.animate({ scrollTop: div[0].scrollHeight},speed);
}
// Folding
function acordion(sel) {
    acdon = true;
    $(sel).next().slideToggle('slow', function() {
        sticky_bottom(0);
        acdon = false;
    });
}
function set_acordion(sel, filter) {
    if (filter) {acordion(sel + filter);}
    $(sel).on('click', function() {
        acordion(this);
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
function get_response(data) {
    if (data) {
        var res = $.parseJSON(data);
        console.log('recv=' + data);
        replace('#msg', res.msg, res.msg.toLowerCase());
        count = 10;
        start_upd();
    }else {
        stop_upd();
        replace('#msg', 'NO Response', 'error');
    }
}
function remain_msg() {
    if (count > 0)
        count -= 1;
    else if (count == 0)
        $('#msg').text('');
}
function dvctl(cmd) {
    var args = {port: port, cmd: cmd};
    console.log('send=' + JSON.stringify(args));
    $.post('/json/dvctl-udp.php', args, get_response);
}
function stop() {
    dvctl('interrupt');
}
// With Confirmation
function exec(cmd) {
    if (confirm('EXEC?(' + cmd + ')')) {
        dvctl(cmd);
        return true;
    }else
        return false;
}
// Select Command
function make_opt(opt, ary) {
    for (var i in ary) {
        if (Array.isArray(ary[i])) {
            opt.push('<optgroup label="' + ary[i][0] + '">');
            make_opt(opt, ary[i][1]);
            opt.push('</optgroup>');
        }else {
            opt.push('<option>' + ary[i] + '</option>');
        }
    }
}
function make_select(obj, ary) {
    var opt = ['<option>--select--</option>'];
    make_opt(opt, ary);
    obj.innerHTML = opt.join('');
}
function seldv(obj) {
    var cmd = obj.options[obj.selectedIndex].value;
    if (cmd == '--select--') return;
    exec(cmd) && make_select(obj, []);
}
// ********* Page Update *********
// Control Part/Shared with ciax-xml.js
function stop_upd() {
    if (!itvl) return;
    clearInterval(itvl);
    itvl = null;
    $('#msg').text('');
}
function start_upd() {
    $('#scroll :checkbox').prop('checked', true);
    if (!itvl) itvl = setInterval(update, 1000);
}
var itvl;
var acdon;
var start_pos = 0;
var count = 0;
$(window).on('resize', height_adjust);
$.ajaxSetup({ cache: false});
