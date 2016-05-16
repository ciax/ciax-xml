// ******* Animation *********
// Auto scroll. Check box with id:go_bottm is needed;
function sticky_bottom() {
    var div = $('.contents');
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
function acordion(top) {
    $(top + ' h4').next().slideToggle('slow');
}
function set_acordion(top, fold) {
    if (fold) {acordion(top);}
    $(top + ' h4').on('click', function() {
        $(this).next().slideToggle();
        height_adjust();
    });
}
// interactive mode
function blinking() {
    $('.query,#msg').fadeOut(500, function() {$(this).fadeIn(500)});
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
// ** CGI **
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
// Not UPD or INTERRUPT
function exec(cmd) {
    if (confirm('EXEC?(' + cmd + ')')) {
        dvctl(cmd);
    }
}
function seldv(obj) {
    var cmd = obj.options[obj.selectedIndex].value;
    if (cmd != '--select--') { exec(cmd); }
    obj.innerHTML = '<option>--select--</option>';
}
// ********* Page Update *********
// Control Part/Shared with ciax-xml.js
function init() {
    update();
    itvl = setInterval(update, 1000);

}
function init_log() {
    select();
    archive('latest');
}
var itvl;
var manual = false;
$(window).on('resize', height_adjust);
$.ajaxSetup({ cache: false});
