// Recommended Package: closure-linter
// fixjsstyle record.js
function update() {
    all = [];
    $.getJSON('rec_list.php', function(data) {
        all.push('<ul>');
        for (var j in data) {
            var date = new Date(j+0)
            all.push('<li>' + date +'/'+ j+ '(' + data[j][0] + ' ->' + data[j][1] +')</li>');
        }
        all.push('</ul>');
        $('#output')[0].innerHTML = all.join('');
    });
}
var all = [];
$(document).ready(update);
