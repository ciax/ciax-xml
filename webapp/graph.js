function get_graph() {
    var time = par[2] - 0;
    var url = 'sqlog.php?site=' + par[0] + '&vid=' + par[1] + '&range=43260000&time=' + time;
    var tol = 180000;
    var min = time - tol;
    var max = time + tol;
    $.getJSON(url, function(data) {
        var options = {
            series: {
                lines: { show: true },
                points: { show: true, radius: 3 }
            },
            grid: {
                markings: [{
                    color: '#ff0000',
                    lineWidth: 3,
                    xaxis: { from: time, to: time }
                }]
            },
            xaxis: {
                mode: 'time',
                timezone: 'browser',
                min: min,
                max: max
            },
            zoom: { interactive: true },
            pan: { interactive: true }
        };
        $.plot($('#placeholder'), [data], options);
    });
}
