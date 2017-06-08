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
    markings: markings,
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
function init_move(){
  $("#placeholder").on("plotclick", show_move);
}
function show_move(event, pos, item){
  if(item){
    par.time = item.datapoint[0].toFixed(2);
    get_graph();
  }
}

function init_tooltip() {
  $("<div id='tooltip'></div>").css({
    position: 'absolute',
    display: 'none',
    border: '1px solid #fdd',
    padding: '2px',
      'background-color': '#fee',
    opacity: 0.80
  }).appendTo('body');
  $('#placeholder').on('plothover', show_tooltip);
}

function show_tooltip(event, pos, item) {
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

function markings(axes) { //Making grid stripe and bar line
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
  if (past_time) mary.push({
    color: '#ff0000',
    lineWidth: 3,
    xaxis: { from: past_time, to: past_time }
  });
  return mary;
}

function init_mode() {
  if (past_time) {
    clearInterval(timer);
    // For static mode
    // set range
    var time = past_time - 0;
    var tol = 180000;
    var min = time - tol;
    var max = time + tol;
    options.xaxis.min = min;
    options.xaxis.max = max;
    options.zoom = { interactive: true };
    options.pan = { interactive: true };
    set_date(past_time);
  }else {
    // For dynamic mode
    timer=setInterval(update, 1000);
  }
}
function update() {
  $.getJSON('sqlog.php', par, function(obj) {
    obj[0].data.forEach(conv_ascii);
    plot.setData(obj);
    plot.setupGrid(); // scroll to left
    plot.draw();
  });
}

function get_log() {
  var url = 'dvlog.php?site=' + par.site + '&vid=' + par.vid;
  if (par.time) {
    url += '&time=' + par.time;
  }
  window.open(url, 'LOG', 'width=320,height=640,scrollbars=yes');
}

function conv_ascii(pair) {
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

function set_date(past_time) {
  var dte = new Date(past_time - offset);
  $('#date').val(dte.toJSON().substr(0, 10));
}

function mv_date(dom) {
  var date = new Date($(dom).val());
  par.time = date.getTime() + offset;
  get_graph();
}
// Main
function get_graph() {
  past_time = par.time;
  init_mode();
  $.getJSON('sqlog.php', par, function(obj) {
    obj[0].data.forEach(conv_ascii);
    series = obj;
    plot = $.plot('#placeholder', series, options);
    init_tooltip();
    init_move();
  });
}

// var par shold be set in html [site, vid, (time)]
var plot;
var series;
var past_time;
var timer;
var offset = (new Date()).getTimezoneOffset() * 60000;
$.ajaxSetup({ mimeType: 'json', ifModified: true, cahce: false});
