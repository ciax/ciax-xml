function init() { get_graph('tap', 'pres'); }
function get_graph(site, vid) {
    $.getJSON('get-log.php?site=' + site + '&vid=' + vid, function(data) {
        var options = { xaxis: { mode: 'time'} };
        $.plot($('#placeholder'), [data], options);
    });
}
