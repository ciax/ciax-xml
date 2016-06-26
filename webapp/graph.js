// Default data range is 12 hour.
// Default display range is 3 min.
// Time param set the absolute unix time for data
var options = {
    series: {
        lines: { show: true },
        points: { show: true, radius: 3 }
    },
    grid: {
        markings: []
    },
    xaxis: {
        mode: 'time',
        timezone: 'browser'
    },
    zoom: { interactive: true },
    pan: { interactive: true }
};
function get_range() {
    if (!par.time) return;
    var time = par.time - 0;
    var tol = 180000;
    var min = time - tol;
    var max = time + tol;
    options.xaxis.min = min;
    options.xaxis.max = max;
    options.grid.markings.push({
        color: '#ff0000',
        lineWidth: 3,
        xaxis: { from: time, to: time }
    });
}

function get_graph() {
    par.range = 43260000;
    $.getJSON('sqlog.php', par, function(data) {
        get_range();
        $.plot($('#placeholder'), data, options);
    });
}
