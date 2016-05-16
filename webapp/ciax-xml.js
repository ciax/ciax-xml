// ******* Animation *********
// Auto scroll. Check box with id:go_bottm is needed;
function sticky_bottom() {
    var div = $('.contents');
    var toggle = $('#go_bottom');
    if (toggle.prop('checked')) {
        auto_release = false;
        div.animate({ scrollTop: div[0].scrollHeight},'slow', function() {
            auto_release = true;
        });
        div.on('scroll', function() {
            if (auto_release) toggle.prop('checked', false);
        });
    }
}
// Folding
function acordion(sel) {
    auto_release = false;
    $(sel).next().slideToggle('slow', function() {
        auto_relase = true;
    });
}
function set_acordion(sel, fold) {
    if (fold) {acordion(sel);}
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
    $('div.outline').each(function() {
        $(this).children('div:not(".contents")').each(function() {
            h = h - $(this).height();
        });
        $(this).children('.contents').css('max-height', h - 100);
    });
}
// ******** Control by UDP ********
function dvctl(cmd) {
    $.post(
        '/json/dvctl-udp.php',
        {port: port, cmd: cmd},
        function(data) {
            $('#msg').text($.parseJSON(data).msg);
            init();
        }
    );
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
    if (cmd != '--select--') exec(cmd);
    make_select(obj, def_sel);
}
// ********* Page Update *********
// Control Part/Shared with ciax-xml.js
function stop_upd() {
    clearInterval(itvl);
    $('#msg').text('No Update');
}
function start_upd() {
    update();
    itvl = setInterval(update, 1000);
}
function init_log() {
    select();
    archive('latest');
}
var itvl;
var auto_release = false;
var def_sel = [];
$(window).on('resize', height_adjust);
$.ajaxSetup({ cache: false});
