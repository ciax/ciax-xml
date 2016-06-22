function init() { get_graph('tap', '1466220000000'); }
function get_graph(site, time) {
    $.getJSON('sqlog.php?site=' + site + '&time=' + time, function(data) {
        var options = {
            xaxis: {
                mode: 'time'
            },
            zoom: {
                interactive: true
            },
            pan: {
                interactive: true
            }
        };
        $.plot($('#placeholder'), [data], options);
    });
}
