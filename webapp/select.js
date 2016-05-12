// Recommended Package: closure-linter
// fixjsstyle select.js
function record_cmd(key, cid) {
    all.push(' <a href="record.php?id=' + key + '" target=frm2>');
    all.push(' <span class="cmd">[' + cid + ']</span>');
    all.push('</a>');
}
function record_res(res) {
    var co = cls[res] ? cls[res] : 'alarm';
    all.push(' -> <span class="' + co + '">');
    all.push(res + '</span>');
}
function time_list(key, time, ary) {
    all.push('<li>');
    all.push('<span class="time">' + time.toLocaleTimeString() + '</span>');
    record_cmd(key, ary[0]);
    record_res(ary[1]);
    all.push('</li>');
}

function date_list(key, ary) {
    var time = new Date(key - 0);
    var crd = time.toLocaleDateString();
    if (date != crd) {
        if (all.length > 0) { all.push('</ul>'); }
        all.push('<h4>' + crd + '</h4><ul style="display:none;">');
        date = crd;
    }
    time_list(key, time, ary);

}
function acordion() {
    $('h4').on('click', function() {
        $(this).next().slideToggle();
    });
}
function select() {
    all = [];
    $.getJSON('select.php', function(data) {
        var keys = [];
        for (var i in data) {
            // Date(j-0) -> cast to num
            date_list(i, data[i]);
        }
        all.push('</ul>');
        $('#output')[0].innerHTML = all.join('');
        acordion();
    });
}
    var all = [];
var cls = { 'complete': 'normal', 'skipped': 'normal', 'interrupted': 'warn', 'busy': 'active'};
    var date = new Date();
    $(document).ready(select);

