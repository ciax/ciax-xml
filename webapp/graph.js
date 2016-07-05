// Default data range is 12 hour.
// Default display range is 3 min.
// Time param set the absolute unix time for data
var options = {
    series: {
        lines: { show: true },
        points: { show: true, radius: 3 }
    },
    grid: {
        markings: markings,
        backgroundColor: { colors: ['#fff', '#999'] },
        hoverable: true
    },
    xaxis: {
        mode: 'time',
        timezone: 'browser'
    },
    yaxis: {
        zoomRange: false,
        panRange: false
    },
    zoom: { interactive: true },
    pan: { interactive: true }
};

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
        var y = item.datapoint[1].toFixed(2);
        $('#tooltip').html(item.series.label + ':' + y)
            .css({ top: item.pageY + 5, left: item.pageX + 5 })
            .fadeIn(200);
    }else {
        $('#tooltip').hide();
    }
}

function markings(axes) { //Making grid strype and bar line
    var mary = [];
    var hour = 3600000;
    var h2 = hour * 2;
    var ax = axes.xaxis;
    var min = ax.min - (ax.min % h2);
    var max = ax.max;
    for (var x = min; x < max; x += h2)
        mary.push({ xaxis: { from: x, to: x + hour}, color: '#999'});
    // bar line
    if (point) mary.push({
        color: '#ff0000',
        lineWidth: 3,
        xaxis: { from: point, to: point }
    });
    return mary;
}

function get_range() {
    if (!point) return;
    var time = point - 0;
    var tol = 180000;
    var min = time - tol;
    var max = time + tol;
    options.xaxis.min = min;
    options.xaxis.max = max;
}

function push_data(e) {
    $.each(dataset, function(i, series) {
        var data = series.data;
        var len = data.length - 1;
        var last = data[len];
        if (!e.time || last[0] == e.time) return;
        series.data.shift();
        series.data.push([e.time, e.data[series.vid]]);
        plot.setData(dataset);
        plot.draw();
    });
}

function update() {
    $.getJSON('status_' + par.site + '.json', push_data);
}

function get_graph() {
    par.range = 43260000;
    $.getJSON('sqlog.php', par, function(ary) {
        point = par.time;
        dataset = ary;
        get_range();
        plot = $.plot('#placeholder', dataset, options);
        init_tooltip();
        if (!point) setInterval(update, 1000);
    });
}

// var par will be set in html
var plot;
var dataset;
var point;
