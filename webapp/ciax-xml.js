//********* Shared **********
function replace(sel, str, cls) {
    return $(sel).text(str).attr('class', cls || str);
}
function open_link(site) {
    window.open('/json/' + site + '.html', site,
                'menubar=no,location=no,status=no,width=800,height=200'
               );
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
    dvctl('interrupt');
}
function interactive() {
    var sel = $('#nonstop :checkbox');
    if (!sel[0]) return;
    if (sel.prop('checked'))
        dvctl('nonstop');
    else
        dvctl('interactive');
}
// Select Command
function make_select(dom, ary) {
    var opt = ['<option>--select--</option>'];
    make_opt(ary);
    $(dom).html(opt.join(''));
    if (ary.length > 0) $('#msg').text('');

    function make_opt(ary) {
        $.each(ary, function(i, val) {
            // Grouping
            if (Array.isArray(val)) {
                opt.push('<optgroup label="' + val[0] + '">');
                make_opt(val[1]);
                opt.push('</optgroup>');
            }else {
                opt.push('<option>' + val + '</option>');
            }
        });
    }
}
function get_select(dom) {
    var cmd = $(dom).val();//options[obj.selectedIndex].value;
    if (cmd == '--select--') return;
    return cmd;
}
function seldv(dom) {
    var cmd = get_select(dom);
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
function update() {
    $.each(upd_list, function(k, func) { func(); });
}
function init() {
    $.each(init_list, function(k, func) { func(); });
    setInterval(update, 1000);
}
var port;
var start_pos = 0;
var upd_list = {};
var init_list = [];
$(window).on('resize', height_adjust);
// ifModified option makes error in FireFox (not Chrome).
// JSON will be loaded as html if no update at getJSON().
$.ajaxSetup({ mimeType: 'json', cahce: false});
