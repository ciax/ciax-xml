function init() { get_graph('tap', 'pres'); }
function get_graph(site, vid) {
    $.getJSON('sqlog.php?site=' + site + '&vid=' + vid, function(data) {
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
