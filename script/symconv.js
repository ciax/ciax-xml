function update(){
    jQuery.ajax({
        url : "status_"+OBJ+".json",
        dataType : 'json',
        cache : false,
        success : function(json){
            for (var h in json){
                if(SYM[h] && SDB[SYM[h]].type == 'string'){
                    tbl=SDB[SYM[h]].record;
                    val=tbl[json[h]];
                    jQuery("#"+h).addClass(val.class);
                    jQuery("#"+h).text(val.msg);
                }else{
                    jQuery("#"+h).text(json[h]);
                }
            }
        }
    })
}
jQuery(document).ready(setInterval(update,3000));
