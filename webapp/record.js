// Need var: Type,Site
function mkcond(conds,all){
    for(var k in conds){
        var cond=conds[k];
        all.push("<li><p>");
        all.push(cond.site + ":" + cond.var);
        all.push(" (" + cond.res + ")" );
        all.push("</p></li>");
    }
}
function mkstep(step, all){
    if(step.conditions){
        all.push("</p><ul>");
        mkcond(step.conditions,all);
        all.push("</ul>");
    }else{
        all.push(" (" + step.site + ")</p>");
    }
}
function take_back(crnt, depth, all){
    while(crnt <= depth){
        all.push("</ul>");
        depth -=1;
    }
    return depth
}

function update(){
    $.getJSON("record_latest.json", function(data) {
        var all = [];
        var depth = 0;
        all.push("<h2>" + data.label +"</h2>");
        all.push("<ul>");
        for(var j in data.steps){
            var step=data.steps[j];
            depth=take_back(step.depth,depth,all);
            all.push("<li><p>" + step.type );
            if(step.type == 'mcr'){
                depth=step.depth;
                all.push("("+step.args[0]+")"+depth+"</p><ul>");
            } else{
                mkstep(step, all);
            }
            all.push("</li>");
        }
        depth=take_back(0,depth,all)
        all.push("<h3>(" + data.result + ")</h3>");
        $("#output")[0].innerHTML = all.join("");
    });
}
function init(){
    update();
    setInterval(update,1000);
}
//$(document).ready(init);
$(document).ready(update);
