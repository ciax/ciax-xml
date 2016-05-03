// Need var: Type,Site
function j2ul(){
    $.getJSON("record_latest.json", function(data) {
        var all = [];
        all.push("<li>" + data.label +"</li>");
        all.push("<ul>");
        for(var j in data.steps){
            var step=data.steps[j];
            all.push("<li>" + step.type);
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
        all.push("</ul>");
        all.push("<li>" + data.result + "<li>");
        $("#output")[0].innerHTML = all.join("");
    });
}
$(document).ready(j2ul);
