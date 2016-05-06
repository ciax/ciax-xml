<?php
define("LOGDIR","/home/omata/.var/json/");
class McrLog{
    var $logdata=array();
    var $logfp;

    function McrLog($filename){
        $this->logfp=(isset($_GET['fp']))?$_GET['fp']:0;
        $hdl=fopen($filename,"r");
        fseek($hdl,$this->logfp);
        while ($data = fgets($hdl)){
            if(ereg("^[0-9]{6}-[0-9]{6}",$data)){
                $ary=explode(" ",$data,3);
                $date=$ary[0];
                $ln=$ary[1];
                $body=ereg_replace("%.*","Done!",$ary[2]);
                $class=$this->htmlClass($body);
                $line=array("fp"=>$this->logfp,"class"=>$class,"date"=>$date,"ln"=>$ln,"body"=>trim($body));
                array_push($this->logdata,$line);
            }
            $this->logfp=ftell($hdl);
        }
        fclose($hdl);
    }

    function htmlClass($str){
        $cls=array('TITLE'=>'#','MCR'=>'MCR:','CMD'=>'[0-9A-Z]{3}:',
        'SYM'=>'\[','OK'=>'OK','NG'=>'NG','ERR'=>'Error',
        'QRY'=>'->','JDG'=>'=>','EXEC'=>'Execute','WAIT'=>'Waiting',
        'DONE'=>'Done');
        $str1=ltrim($str);
        $spclen=round((strlen($str)-strlen($str1))/2);
        $rank=($spclen>0)?" R".$spclen:"";
        foreach ($cls as $key => $val){
            if(ereg("^$val",$str1)){
                return($key.$rank);
            }
        }
        return('STD'.$rank);
    }

    function getFp(){
        return $this->logfp;
    }

    function getTbody(){
        $tbody='';
        foreach($this->logdata as $line){
            $tbody.='<tr><td>';
            $tbody.=htmlentities($line['date']);
            $tbody.="</td>\n";
            $tbody.='<td>';
            $tbody.=htmlentities($line['ln']);
            $tbody.="</td>\n";
            $tbody.='<td class="'.$line['class'].'">';
            $tbody.=htmlentities($line['body']);
            $tbody.="</td></tr>\n";
        }
        return $tbody;
    }

    function getJson(){
        $json="[\n";
        foreach ($this->logdata as $line){
            $json.='{ "fp":"'.$line['fp'];
            $json.='","class":"';
            $json.=$line['class'];
            $json.='","date":"';
            $json.=$line['date'];
            $json.='","body":"';
            $json.=$line['body'];
            $json.='"},'."\n";
        }
        $json.='"'.$this->logfp.'"'."\n]";
        return $json;
    }

    function getXml(){
        $xmlbody='<?xml version="1.0" encoding="UTF-8" ?>'."\n";
        $xmlbody.="<mcrlog>\n";
        foreach($this->logdata as $line){
            $xmlbody.='<line fp="'.$line['fp'];
            $xmlbody.='" class="'.$line['class'].'">'."\n";
            $xmlbody.="<date>";
            $xmlbody.=htmlentities($line['date']);
            $xmlbody.="</date>\n";
            $xmlbody.="<str>";
            $xmlbody.=htmlentities($line['body']);
            $xmlbody.="</str>\n";
            $xmlbody.="</line>\n";
        }
        $xmlbody.="<endfp>".$this->logfp."</endfp>\n";
        $xmlbody.="</mcrlog>\n";
        return $xmlbody;
    }

}

class LogDate{
    var $dateline=array('a0','a1');
    var $selected;

    function LogDate(){
        array_push($this->dateline,array('a1','a2');
        foreach(glob(LOGDIR."record*.json") as $val){
            ereg('([0-9]{6})',$val,$s1);
            ereg(LOGDIR.'(.*)',$val,$s2);
            array_push($this->dateline,array($s1[0],$s2[1]));
        }
        rsort($this->dateline);
        $fname=LOGDIR;
        if(isset($_GET['file'])){
            $fname.=$_GET['file'];
        }else{
            $line=$this->dateline;
            $fname.=$line[0][1];
        }
        $this->selected=$fname;
    }

    function getList(){
        return $this->dateline;
    }

    function getFname(){
        return $this->selected;
    }

    function isToday(){
        $date=date('ymd');
        return ereg($date,$this->selected);
    }
}
?>
