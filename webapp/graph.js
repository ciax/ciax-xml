// Data range is 100 points
// Display range is 10 points
// Time param set the absolute unix time for data
var options = {
  series: {
    shadowSize: 0,
    lines: {
      show: true
    },
    points: {
      show: true,
      radius: 3
    }
  },
  grid: {
    markings: _mk_markings,
    backgroundColor: {
      colors: ['#fff', '#999']
    },
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
// Update current date
function current_date(msec) {
  current.setTime(msec - offset);
  $('#date').val(current.toJSON().slice(0, 10));
}

// Move Time Range
function init_move() {
  $('#placeholder').on('plotclick', _move_time);
}
function _move_time(event, pos, item) {
  if (item) {
    par.time = item.datapoint[0].toFixed(2);
    past_graph();
  }
}

function move_date(dom) {
  par.time = Date.parse($(dom).val()) + offset;
  past_graph();
}

function move_fw() {
  par.time = range[0];
  past_graph();
}

function move_bk() {
  par.time = range[1];
  past_graph();
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
    var x = date.toLocaleString('en-US', {
      hour12: false
    });
    var y = item.datapoint[1].toFixed(2);
    $('#tooltip').html(x + ',' + y)
      .css({
        top: item.pageY + 5,
        left: item.pageX + 5
      })
      .fadeIn(200);
  } else {
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
    mary.push({
      xaxis: {
        from: x,
        to: x + hour
      },
      color: '#999'
    });
  // bar line
  if (par.time) mary.push({
    color: '#ff0000',
    lineWidth: 3,
    xaxis: {
      from: par.time,
      to: par.time
    }
  });
  return mary;
}

// Pop Up Log Table
function get_log() {
  var url = 'dvlog.html?site=' + par.site + '&vid=' + par.vid;
  if (par.time) {
    url += '&time=' + par.time;
  }
  window.open(url, 'LOG', 'width=320,height=640,scrollbars=yes');
}

// **** Main ****
// Convert String to Number for Graph
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
  var time = pair[0];
  if (range[0] < time) {
    range[0] = time;
  }else if (range[1] > time) {
    range[1] = time;
  }
}

function _regurate(obj) {
    var dat = obj[0].data;
    var typ = dat[0][0];
    range = [typ, typ];
    dat.forEach(_conv_ascii);
}
// Dynamic Graph
function update_graph() {
  $.getJSON('sqlog.php', par, function(obj) {
    _regurate(obj);
    plot.setData(obj);
    plot.setupGrid(); // scroll to left
    plot.draw();
  });
}

function static_graph(zoom) {
  current_date(par.time || Date.now());
  $.getJSON('sqlog.php', par, function(obj) {
    _regurate(obj);
    plot = $.plot($('#placeholder'), obj, options);
    if (zoom) {
      plot.zoom({
        amount: zoom
      });
    }
  });
}

function current_graph() {
  timer = setInterval(update_graph, 1000);
  delete par.time;
  pz(false);
  static_graph();
}

function past_graph() {
  clearInterval(timer);
  pz(true);
  static_graph();
}

function pz(tf) {
  options.zoom = {
    interactive: tf
  };
  options.pan = {
    interactive: tf
  };
}

function init_graph() {
  init_tooltip();
  init_move();
  if (par.time) {
    past_graph();
  } else {
    current_graph();
  }
}

// var par shold be set in html [site, vid, (time)]
var plot;
var timer;
var current = new Date();
var offset = current.getTimezoneOffset() * 60000;
var range = [0.0];
$.ajaxSetup({
  mimeType: 'json',
  ifModified: true,
  cahce: false
});
$(init_graph);
