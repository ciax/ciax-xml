// ******* Animation *********
// Auto scroll. Check box with id:go_bottm is needed;
function sticky_bottom() {
    var div = $('#record');
    var toggle = $('#scroll :checkbox');
    if (toggle.prop('checked')) {
        auto_release = false;
        div.animate({ scrollTop: div[0].scrollHeight},'slow', function() {
            auto_release = true;
        });
        div.hover(null, function() { auto_release = false; });
        div.on('scroll', function() {
            if (auto_release) toggle.prop('checked', false);
        });
    }
}
// Folding
function acordion(sel) {
    auto_release = false;
    $(sel).next().slideToggle('slow', function() {
        sticky_bottom();
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
    $('.query,.run').fadeOut(500, function() {$(this).fadeIn(500)});
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
    });
}
// ******** Control by UDP ********
function get_response(data) {
    if (data) {
        var res = $.parseJSON(data);
        console.log('recv=' + data);
        $('#msg').text(res.msg);
        count = 10;
        start_upd();
    }else {
        stop_upd();
        $('#msg').text('NO Response');
        $('#msg').attr('class', 'error');
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
    if (confirm('EXEC?(' + cmd + ')')) dvctl(cmd);
}
// Select Command
function make_select(obj, ary) {
    var opt = ['<option>--select--</option>'];
    for (var i in ary) {
        opt.push('<option>' + ary[i] + '</option>');
    }
    obj.innerHTML = opt.join('');
}
function seldv(obj) {
    var cmd = obj.options[obj.selectedIndex].value;
    if (cmd == '--select--') return;
    exec(cmd);
    if (itvl) make_select(obj, def_sel);
}
// ********* Page Update *********
// Control Part/Shared with ciax-xml.js
function stop_upd() {
    if (itvl) {
        clearInterval(itvl);
        itvl = false;
        $('#msg').text('');
    }
}
function start_upd() {
    if (!itvl) itvl = setInterval(update, 1000);
}
var itvl;
var auto_release = false;
var def_sel = [];
var count = 0;
$(window).on('resize', height_adjust);
$.ajaxSetup({ cache: false});
