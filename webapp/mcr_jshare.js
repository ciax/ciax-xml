var fp=0;
var fname='';
function init(file,ifp){
    fp=ifp;
    fname=file;
    tbody=$('mcr');
    setInterval(update,3000);
}
function update(){
    var url="mcr_json.php";
    var pars='file='+fname+'&fp='+fp+'&cache='+(new Date()).getTime();
    new Ajax.Request(url,{
        method:"GET",
	parameters: pars,
	onComplete:append});
}
function append(n){
    lines=eval("("+n.responseText+")");
    fp=lines.pop();
    for(i=0;i<lines.length;i++){
	tbody.appendChild(logline(lines[i]));
	scrollBy(0,30);
    }
}
function logline(line){
    var tr=document.createElement("tr");
    var td1=document.createElement("td");
    var td2=document.createElement("td");
    var date=document.createTextNode(line["date"]);
    td1.appendChild(date);
    tr.appendChild(td1);
    Element.addClassName(td2,line["class"]);
    var stat=document.createTextNode(line["body"]);
    td2.appendChild(stat);
    tr.appendChild(td2);
    return tr;
}
