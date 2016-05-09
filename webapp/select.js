// Recommended Package: closure-linter
// fixjsstyle select.js
function time_list(time, cid, res) {
    all.push('<li>' + time.toLocaleTimeString());
    all.push(' [<span class="cmd">' + cid + '</span>]');
    var co = cls[res] ? cls[res] : 'alarm';
    all.push(' -> <span class="' + co + '">');
    all.push(res + '</span>');
    all.push('</li>');
}

function date_list(time, cid, res) {
    var crd = time.toLocaleDateString();
    if (date != crd) {
        all.push('</ul><h4>' + crd + '</h4><ul>');
        date = crd;
    }
    time_list(time, cid, res);
}
function update() {
    all = [];
    $.getJSON('rec_list.php', function(data) {
        all.push('<ul>');
        for (var j in data) {
            // Date(j-0) -> cast to num
            date_list(new Date(j - 0), data[j][0], data[j][1]);
        }
        all.push('</ul>');
        $('#output')[0].innerHTML = all.join('');
    });
}
    var all = [];
    var cls = { 'complete': 'normal', 'interrupted': 'warn', 'busy': 'active'};
    var date = new Date();
    $(document).ready(update);

