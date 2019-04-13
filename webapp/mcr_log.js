// Recommended Package: closure-linter
// fixjsstyle mcr_log.js
// Listing part
function make_item(id, data) {
  function _line() {
    _time();
    _cmd();
    _res(data.result);
  }

  function _time() {
    html.push('<span class="time" title="' + id + '">');
    html.push(time.toLocaleTimeString('en-US', {
      hour12: false
    }));
    html.push('</span>');
  }

  function _cmd() {
    html.push(' <span class="cmd">[' + data.cid + ']</span>');
  }

  function _res(res) {
    html.push(' -> ');
    html.push('<em class="' + res + '">' + res + '</em>');
  };

  var html = [];
  var time = new Date(id - 0);
  // Date(j-0) -> cast to num
  html.push('<li id="' + id + '">');
  _line();
  html.push('</li>');
  return html.join('');
}

function func_make_list() {
  function _upd_item(id, data) {
    var jq = $('#' + id);
    if (!jq[0]) return;
    var em = jq.children('em');
    if (em.text() == 'busy') {
      var res = data.result;
      em.text(res).attr('class', res);
    }
    return true;
  }

  function _make_year(time) {
    var cyr = time.getFullYear();
    if (year != cyr) {
      year = cyr;
      _make_tree(year, year, 'log');
    }
  }

  function _make_date(time) {
    var dary = time.toLocaleDateString().split('/');
    var dti = dary[1] + '/' + dary[2];
    var did = dary.join('_');
    if (!$('#' + did)[0]) {
      _make_year(time);
      _make_tree(dti, did, year);
    }
    return $('#' + did);
  }

  // Latest Top
  function _make_tree(title, id, pid) {
    var html = [];
    html.push('<h4>' + title + '</h4>');
    html.push('<ul id="' + id + '"></ul>');
    $('#' + pid).prepend(html.join(''));
  }

  function _sort_keys(a, b) {
    var na = a - 0;
    var nb = b - 0;
    if (na < nb) return -1;
    if (na > nb) return 1;
    return 0;
  }

  function _upd_line(id, item) {
    var time = new Date(id - 0);
    _upd_item(id, item) || _make_date(time).prepend(make_item(id, item));
  }

  function _init_log() {
    if (again) return;
    // Set first selected
    set_acordion('#log')(':gt(1)');
    again = 1;
  }

  function _select() {
    if ($('#log li').hasClass('selected')) return;
    $('#log li').first().trigger('click');
  }

  function _update(data) {
    if (!data) return;
    var ids = Object.keys(data.dic).sort(_sort_keys);
    for (var i of ids) {
      _upd_line(i, data.dic[i]);
    }
    // blinking status
    blinking();
    _init_log();
    _select();
  }

  var year = '';
  var again;
  return _update;
}

function new_record(id) {
  $('#log li').removeClass('selected');
  update_record(id);
}

function update_list() {
  ajax_update('list_record.json').done(make_list);
}

function toggle_dvctl() {
  $('.dvctl').fadeToggle(1000, height_adjust);
}

// Initial Setting
function init_log() {
  function _switch_record(id) {
    $('#log li').removeClass('selected');
    $('#' + id).addClass('selected');
    // Activate selected record
    update_record(id);
  }

  function _on_click() {
    if ($(this).hasClass('selected')) return;
    _switch_record($(this).attr('id'));
  }

  // Set click event
  $('#log').on('click', 'li', _on_click);
  upd_list.log = update_list;
}

init_list.push(init_log);
var make_list = func_make_list();
