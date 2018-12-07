// var par shold be set in html [site, vid, (time)]
$.getJSON('sqlog.php', par, function(obj) {
  $('.title').append('<span class="head">' + par.site + ':' + par.vid + '</span>');
  obj[0].data.forEach(function(pair) {
    var datetime = new Date(pair[0] - 0);
    var tr = '<tr><td>';
    tr += '<span class="label" title="' + datetime.toLocaleDateString('en-US') + '">';
    tr += datetime.toLocaleTimeString('en-US', {
      hour12: false
    });
    tr += '</span></td><td class="item"><var>';
    tr += pair[1] + '</var></td></tr>';
    $('tbody').append(tr);
  });
});
