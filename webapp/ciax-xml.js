// ******* Animation *********
// auto scroll
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
function acordion(click) {
    if (click) { $('h4').next().slideToggle(); }
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
    if (!confirm('EXEC?(' + cmd + ')')) return;
    $.post(
        '/json/dvctl-udp.php',
        {port: port, cmd: cmd},
        function(data) {
            $('#msg').text($.parseJSON(data).msg);
            update();
            alert($('#msg').text());
        }
    );
}
function seldv(obj) {
    var cmd = obj.options[obj.selectedIndex].value;
    if (cmd != '--select--') {  dvctl(cmd); }
}
// ********* Page Update *********
// Control Part/Shared with ciax-xml.js
function init() {
    $.ajaxSetup({ cache: false});
    $('#query').hide();
    update();
    $(window).on('resize', adjust);
    itvl = setInterval(update, 1000);

}
var itvl;
