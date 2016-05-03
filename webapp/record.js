// Need var: Type,Site
function mkstep(step, all){
    if(step.conditions){
        all.push("<ul>");
        for(var k in step.conditions){
            var cond=step.conditions[k];
            all.push("<li>" + cond.site + ":" + cond.var + " (" + cond.res + ")" + "</li>");
        }
        all.push("</ul>");
    }else{
        all.push(" (" + step.site + ")");
    }
    all.push("</li>");
}

function update(){
    $.getJSON("record_latest.json", function(data) {
        var all = [];
        var depth = 0;
        all.push("<li>" + data.label +"</li>");
        all.push("<ul>");
        for(var j in data.steps){
            var step=data.steps[j];
            if(step.depth == depth){
                all.push("</ul>")
                depth-=1;
            }
            all.push("<li>" + step.type);
            if(step.type == 'mcr'){
                all.push("("+step.args[0]+")<ul>");
                depth=step.depth;
            } else{
                mkstep(step, all);
            }
        }
        all.push("</ul>");
        all.push("<li>(" + data.result + ")</li>");
        $("#output")[0].innerHTML = all.join("");
    });
}
function init(){
    update();
    setInterval(update,1000);
}
$(document).ready(init);
