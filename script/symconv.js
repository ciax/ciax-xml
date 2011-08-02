function convert(table,val){
    var view;
    var tbl=table.record;
    var def=tbl['default']||{class:'normal',msg:val};
    switch (table.type){
    case 'string':
        view=tbl[val]||def;
        break;
    case 'regexp':
        for(var key in tbl){
            view=tbl[key];
            if(RegExp(key).test(val))
                break;
        }
        break;
    default:
        view=def;
        break;
    }
    return view;
}
function update(){
    jQuery.ajax({
        url : "status_"+OBJ+".json",
        dataType : 'json',
        cache : false,
        success : function(status){
            for (var id in status){
                var val=status[id];
                if(SYM[id]){
                    var view=convert(SDB[SYM[id]],val);
                    jQuery("#"+id).addClass(view.class);
                    val=view.msg;
                }
                jQuery("#"+id).text(val);
            }
        }
    })
}
jQuery(document).ready(setInterval(update,3000));
