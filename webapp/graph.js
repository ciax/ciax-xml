// Data range is 100 points
// Display range is 10 points
// Time param set the absolute unix time for data
var options = {
  series: {
    shadowSize: 0,
    lines: { show: true },
    points: { show: true, radius: 3 }
  },
  grid: {
    markings: _mk_markings,
    backgroundColor: { colors: ['#fff', '#999'] },
    hoverable: true,
    clickable: true
  },
  xaxis: {
    mode: 'time',
    timezone: 'browser'
  },
  yaxis: {
    zoomRange: false,
    panRange: false
  }
};

// **** Optional Functions ****
// Setting Range
function _set_range() {
  clearInterval(timer);
  var time = par.time - 0;
  var tol = 3600000;
  var min = time - tol;
  var max = time + tol;
  options.xaxis.min = min;
  options.xaxis.max = max;
  options.zoom = { interactive: true };
  options.pan = { interactive: true };
}
// Move Time Range
function init_move() {
  $('#placeholder').on('plotclick', _move_time);
}
function _move_time(event, pos, item) {
  if (item) {
    par.time = item.datapoint[0].toFixed(2);
    _set_range();
    static_graph();
  }
}

function move_date(dom) {
  var date = new Date($(dom).val());
  par.time = date.getTime() + offset;
  _set_range();
  static_graph();
}

// Show Tool Tip
function init_tooltip() {
  $("<div id='tooltip'></div>").css({
    position: 'absolute',
    display: 'none',
    border: '1px solid #fdd',
    padding: '2px',
      'background-color': '#fee',
    opacity: 0.80
  }).appendTo('body');
  $('#placeholder').on('plothover', _show_tooltip);
}

function _show_tooltip(event, pos, item) {
  if (item) {
    var date = new Date(item.datapoint[0]);
    var x = date.toLocaleString('en-US', {hour12: false});
    var y = item.datapoint[1].toFixed(2);
    $('#tooltip').html(x + ',' + y)
      .css({ top: item.pageY + 5, left: item.pageX + 5 })
      .fadeIn(200);
  }else {
    $('#tooltip').hide();
  }
}

// Make Marking Setting
function _mk_markings(axes) { //Making grid stripe and bar line
  var mary = [];
  var hour = 3600000;
  var h2 = hour * 2;
  var ax = axes.xaxis;
  var min = ax.min - (ax.min % h2);
  var max = ax.max;
  // trid stripe
  for (var x = min; x < max; x += h2)
    mary.push({ xaxis: { from: x, to: x + hour}, color: '#999'});
  // bar line
  if (par.time) mary.push({
    color: '#ff0000',
    lineWidth: 3,
    xaxis: { from: par.time, to: par.time }
  });
  return mary;
}

// Pop Up Log Table
function get_log() {
  var url = 'dvlog.php?site=' + par.site + '&vid=' + par.vid;
  if (par.time) {
    url += '&time=' + par.time;
  }
  window.open(url, 'LOG', 'width=320,height=640,scrollbars=yes');
}

// **** Main ****
// Shared
function _conv_ascii(pair) {
  if (isNaN(pair[1])) {
    var asc = 0;
    var ary = pair[1].split('').map(function(n) {
      var i = n.charCodeAt(0) - 64;
      return i;
    });
    // regulate to minimum code value
    for (var i = 0; i < ary.length; i++) {
      asc += ary[i] * Math.pow(2, i);
    }
    pair[1] = asc;
  }
}

function update_graph() {
  $.getJSON('sqlog.php', par, function(obj) {
    obj[0].data.forEach(_conv_ascii);
    plot.setData(obj);
    plot.setupGrid(); // scroll to left
    plot.draw();
  });
}

function static_graph() {
  $.getJSON('sqlog.php', par, function(obj) {
    obj[0].data.forEach(_conv_ascii);
    plot = $.plot($('#placeholder'), obj, options);
  });
}

// Main
function init_graph() {
  init_tooltip();
  init_move();
  static_graph();
}

// var par shold be set in html [site, vid, (time)]
var plot;
var offset = (new Date()).getTimezoneOffset() * 60000;
var timer = setInterval(update_graph, 1000);
$.ajaxSetup({ mimeType: 'json', ifModified: true, cahce: false});
$(init_graph);
