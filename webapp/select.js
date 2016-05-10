// Recommended Package: closure-linter
// fixjsstyle select.js
function time_list(key, time, cid, res) {
    all.push('<li>');
    all.push('<span class="time">' + time.toLocaleTimeString() + '</span>');
    all.push('<a href="record.php?id=' + key + '" target=FRM2>');
    all.push(' [<span class="cmd">' + cid + '</span>]');
    all.push('</a>');
    var co = cls[res] ? cls[res] : 'alarm';
    all.push(' -> <span class="' + co + '">');
    all.push(res + '</span>');
    all.push('</li>');
}

function date_list(key, ary) {
    var time=new Date(key - 0);
    var crd = time.toLocaleDateString();
    if (date != crd) {
        all.push('</ul><h4>' + crd + '</h4><ul>');
        date = crd;
    }
    time_list(key, time, ary[0], ary[1]);
}
function update() {
    all = [];
    $.getJSON('select.php', function(data) {
        var keys=[];
        for (var j in data){ keys.push(j); }
        keys.reverse();
        all.push('<ul>');
        for (var i = 0; i < keys.length; i++) {
            // Date(j-0) -> cast to num
            var key=keys[i];
            date_list(key, data[key]);
        }
        all.push('</ul>');
        $('#output')[0].innerHTML = all.join('');
    });
}
    var all = [];
    var cls = { 'complete': 'normal', 'interrupted': 'warn', 'busy': 'active'};
    var date = new Date();
    $(document).ready(update);

