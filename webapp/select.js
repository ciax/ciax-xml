// Recommended Package: closure-linter
// fixjsstyle record.js
function update() {
    all = [];
    $.getJSON('rec_list.php', function(data) {
        all.push('<ul>');
        for (var j in data) {
            var date = new Date(j-0) // cast to num
            var res=data[j][1];
            all.push('<li>' + date);
            all.push('[<span class = "label">' + data[j][0] + '</span>');
            var co=cls[res] ? cls[res] : 'alarm';
            all.push(' -> <span class="' + co + '">');
            all.push(res +'</span>]');
            all.push('</li>');
        }
        all.push('</ul>');
        $('#output')[0].innerHTML = all.join('');
    });
}
var all = [];
var cls={ 'complete':'normal', 'interrupted':'warn', 'busy':'active'}
$(document).ready(update);
