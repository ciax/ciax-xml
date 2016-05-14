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
function acordion(click) {
    if (click) { $('h4').next().slideToggle('slow'); }
    $('h4').on('click', function() {
        $(this).next().slideToggle();
        adjust();
    });
}
// interactive mode
function blinking() {
    $('.query').fadeOut(500, function() {$(this).fadeIn(500)});
}
// contents resize
function adjust() {
    var h = $(window).height();
    // sum height of children in .outline except .contents
    $('div.outline > div:not(".contents")').each(function(){
        h=h-$(this).height();
    });
    $('.contents').css('max-height', h-100);
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
    if (cmd != '--select--') {  exec(cmd); }
}
// ********* Page Update *********
// Control Part/Shared with ciax-xml.js
function init() {
    update();
    itvl = setInterval(update, 1000);

}
var itvl;
var manual=false;
$(window).on('resize', adjust);
$.ajaxSetup({ cache: false});
