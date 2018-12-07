//********* Shared **********
function json_view(data) {
  return (JSON.stringify(data).replace(/"/g, "'"));
}

function replace(sel, str, cls) {
  return $(sel).text(str).attr('class', cls || str);
}

function open_table(site) {
  window.open('/json/' + site + '.html', 't' + site,
    'menubar=no,location=no,status=no,width=600,height=200'
  ).focus();
}

function open_graph(site, vid, time) {
  var url = '/json/graph.html?site=' + site + '&vid=' + vid;
  var pre = 'g' + vid.replace(/,/g, '_');
  if (time) {
    url = url + '&time=' + time;
    pre += 'h';
  }
  window.open(url, pre + '_' + site,
    'menubar=no,location=no,status=no,width=700,height=380'
  ).focus();
}

function exec_funcs(funclist) {
  $.each(funclist, function(k, func) {
    func();
  });
}
// ******* Animation *********
// Auto scroll. Check box with id:go_bottm is needed;
function sticky_bottom(speed) {
  if (!$('#scroll :checkbox').prop('checked')) return;
  var div = $('#record');
  div.animate({
    scrollTop: div[0].scrollHeight
  }, speed);
}

function set_sticky_bottom() {
  $('#scroll :checkbox').prop('checked', true);
}
// Use 'this' inside of $.on()
function set_auto_release(sel) {
  var div = $(sel);
  start_pos = div.scrollTop();
  div.on('mouseenter', function() {
    $(this).on('scroll', auto_release);
  });
  div.on('mouseleave', function() {
    $(this).off('scroll', auto_release);
  });

  function auto_release() {
    var cr = $(this).scrollTop();
    if (cr < start_pos && !$('#record :animated')[0])
      $('#scroll :checkbox').prop('checked', false);
    start_pos = cr;
  }
}
// Folding
function set_acordion(sel) {
  $(sel).on('click', 'h4', function() {
    toggle(this);
  });
  // All list will be folded when titie is clicked
  $(sel).parent().on('click', '.title', function() {
    toggle(sel + ' h4');
  });
  // Initiate after generating page
  return function(sub) {
    toggle(sel + ' h4' + sub);
  }

  function toggle(sub) {
    $(sub).next().slideToggle('slow', function() {
      sticky_bottom(0);
    });
  }
}
// interactive mode
function blinking() {
  $('.query,.run,.busy').fadeOut(500, function() {
    $(this).fadeIn(500);
  });
}
// contents resize
function height_adjust() {
  // sum height of children in .outline except .contents
  $('.outline').each(function(i, ol) {
    var h = $(window).height();
    var res = $(ol).children('div:not(".contents")').map(function(j, e) {
      return $(e).height();
    }).get().reduce(function(p, c, i, arr) {
      return p + c;
    });
    $(ol).children('.contents').css('max-height', h - res - 100);
    sticky_bottom(0);
  });
}
// ******** Control by UDP ********
// dvctl with func when success
function dvctl(args, func) {
  var send = {
    port: port,
    cmd: args
  };
  //console.log('send=' + JSON.stringify(data));
  $.ajax('/json/dvctl-udp.php', {
    data: send,
    ifModified: true,
    cache: false,
    success: function(recv) {
      //console.log('recv=' + JSON.stringify(recv));
      replace('#msg', recv.msg, recv.msg.toLowerCase()).show().fadeOut(1000);
      if (func) {
        console.log(JSON.stringify(recv));
        func(recv.sid);
      }
    },
    error: function(recv) {
      //console.log('recv=' + JSON.stringify(recv));
      replace('#msg', 'NO Response', 'error');
    }
  });
}
// With Confirmation
function exec(csv, func) {
  var args = csv.split(':');
  if (confirm('EXEC?' + JSON.stringify(args))) {
    dvctl(args, func);
    return true;
  } else
    return false;
}
// Button/Check
function stop() {
  dvctl(['interrupt']);
}

function upd() {
  dvctl(['upd']);
}

function interactive() {
  var jq = $('#interactive :checkbox'); // :checlbox
  if (!jq[0]) return;
  if (jq.prop('checked'))
    dvctl(['interactive']);
  else
    dvctl(['nonstop']);
}
// Select Command
function make_select(sel, ary) {
  var jq = $(sel);
  if (!jq[0]) return;
  var opt = ['<option>--select--</option>'];
  make_opt(ary);
  jq.html(opt.join(''));
  if (ary.length > 0) $('#msg').text('');

  function make_opt(ary) {
    $.each(ary, function(key, val) {
      if (typeof key === 'number') {
        make_optpar(key, val);
      } else {
        make_optgrp(key, val);
      }
    });
  }
  // Command with Parameter
  function make_optpar(key, val) {
    opt.push('<option');
    if (Array.isArray(val)) {
      opt.push(' value="' + val[0] + '">' + val[1]);
    } else {
      opt.push('>' + val);
    }
    opt.push('</option>');
  }
  // Grouping
  function make_optgrp(key, val) {
    if (Array.isArray(val)) {
      opt.push('<optgroup label="' + key + '">');
      make_opt(val);
      opt.push('</optgroup>');
    } else {
      opt.push('<option>' + key + '</option>');
    }
  }
}

function get_select(dom) {
  var cmd = $(dom).val(); //options[obj.selectedIndex].value;
  if (cmd == '--select--') return;
  return cmd;
}
// Radio Button
function make_radio(dom, ary) {
  var opt = [];
  $.each(ary, function(i, val) {
    opt.push('<label>');
    opt.push('<input type="radio" name="query" value="');
    if (Array.isArray(val)) {
      opt.push(val[0] + ':' + val[1] + '"/>' + val[0]);
    } else {
      opt.push(val + '"/>' + val);
    }
    opt.push('</label>');
  });
  $(dom).html(opt.join(''));
}
// ********* Ajax *********
function ajax_static(url) {
  return $.ajax(url, {
    ifModified: false,
    cache: true
  });
}
// func1 for updated, func2 for no changes
function ajax_update(url) {
  return $.ajax(url, {
    ifModified: true,
    cache: false
  });
}
// ********* Page Update *********
// Control Part/Shared with ciax-xml.js
function update() {
  exec_funcs(upd_list);
  blinking();
}

function init() {
  exec_funcs(init_list);
  setInterval(update, 1000);
}
var port;
var start_pos = 0;
var upd_list = {}; // Regular Update functions, element can be set/deleted
var init_list = []; // Global Init functions, element will be added only
$(window).on('resize', height_adjust);
// ifModified option makes error in FireFox (not Chrome).
// JSON will be loaded as html if no update at getJSON().
$.ajaxSetup({
  mimeType: 'json',
  cahce: false
});
