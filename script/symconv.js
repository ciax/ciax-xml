function update(){
  jQuery.ajax({
    url : "status_"+OBJ+".json",
    dataType : 'json',
    cache : false,
    success : function(json){
      for (var h in json){
        jQuery("#"+h).text(json[h]);
      }
    }
  })
}
jQuery(document).ready(setInterval(update,3000));
