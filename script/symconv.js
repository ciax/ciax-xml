function Range(str){
    var eq,max,min,min_ex,max_ex;
    if(/:/.test(str)){
        var a=str.split(':');
        min=a[0];max=a[1];
        if(min){
            var m=min.replace(/<$/,'');
            if(m != min)
                min_ex=1;
            min=Number(m);
        }
        if(max){
            var m=max.replace(/^</,'')
            if(m != max)
                max_ex=1;
            max=Number(m);
        }
    }else{
        eq=Number(str);
    }
    this.cmp = function(num){
        if(eq){
            if(eq > num){
                return 1;
            }else if(eq < num){
                return -1;
            }else{
                return 0;
            }
        }else if(min_ex && min >= num){
            return 1;
        }else if(min && min > num){
            return 1;
        }else if(max_ex && max <= num){
            return -1;
        }else if(max && max < num){
            return -1;
        }else{
            return 0;
        }
    }
}
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
    case 'range':
        for(var range in tbl){
            var v=tbl[range];
            view={msg:v.msg+'('+val+')',class:v.class};
            var re=new Range(range);
            if(re.cmp(val) == 0)
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
