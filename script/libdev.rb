#!/usr/bin/ruby
require "libxmldoc"
require "libiocmd"
require "libiofile"
require "libvar"
require "libdevcmd"
require "libdevrsp"

# Main
class Dev
  attr_reader :cid,:field

  def initialize(dev,id)
    @ddb=XmlDoc.new('ddb',dev)
  rescue RuntimeError
    abort $!.to_s
  else
    @v=Verbose.new("ddb/#{id}".upcase)
    @cid=String.new
    @cmdcache=Hash.new
    @fd=IoFile.new("field_#{id}")
    @var=Var.new
    @rsp=DevRsp.new(@ddb,@var)
    @cmd=DevCmd.new(@ddb,@var)
    begin
      @var.stat=@fd.load_stat
    rescue
      warn "----- Create field_#{id}.mar"
      @rsp.init_field{"0"}
      @var.stat['device']=@ddb['id']
      @var.stat['id']=id
    end
    @field=@var.stat
  end

  def setcmd(stm)
    @cid=stm.join(':')
    par=stm.dup
    @var.setstm(par)
    @xpsend=@ddb.select_id('cmdselect',par.shift)
    a=@xpsend.attributes
    @v.msg{'Select:'+a['label']}
    res=a['response']
    @xprecv= res ? @ddb.select_id('rspselect',res) : nil
  end

  def getcmd
    return unless @xpsend
    if @xpsend.attributes['nocache']
      @cmd.cmdframe(@xpsend)
    elsif cmd=@cmdcache[@cid]
      @v.msg{"Cmd cache found [#{@cid}]"}
      cmd
    else
      @cmdcache[@cid]=@cmd.cmdframe(@xpsend)
    end
  end

  def setrsp(time=Time.now)
    return "Send Only" unless @xprecv
    @rsp.rspframe(@xprecv){yield}
    @var.stat['time']="%.3f" % time.to_f
    @fd.save_stat(@var.stat)
  end

end

class DevCom < Dev
  def initialize(dev,id,iocmd)
    super(dev,id)
    @ic=IoCmd.new(iocmd,'device_'+id,@ddb['wait'],1)
  end

  def devcom(stm)
    setcmd(stm)
  rescue SelectID
    case stm.shift
    when 'set'
      set(stm)
    when 'load'
      load(stm.shift)
    when 'save'
      save(stm.shift,stm.shift)
    else
      msg=[$!.to_s]
      msg << "== Data Handling =="
      msg << " set       : Set Value  [key(:idx)(=val)]"
      msg << " load      : Load Field (tag)"
      msg << " save      : Save Field [key,key...] (tag)"
      raise SelectID,msg.join("\n")
    end
  else
    @ic.snd(getcmd,'snd:'+@cid)
    setrsp(@ic.time){ @ic.rcv('rcv:'+@cid) }
  end

  def set(stm)
    if stm.empty?
      msg=["== Option list =="]
      msg << " key(:idx)  : Show Value"
      msg << " key(:idx)= : Set Value"
      msg << " key=#{@var.stat.keys}"
      raise SelectID,msg.join("\n")
    end
    @v.msg{"CMD:set#{stm}"}
    stat={}
    stm.each{|e|
      key,val=e.split('=')
      h=@var.acc_stat(key)
      h.replace(eval(@var.sub_var(val)).to_s) if val
      stat[key]=@var.stat[key]
    }
    stat
  end

  def load(tag='default')
    @var.stat.update(@fd.load_stat(tag))
  end
 
  def save(keys=nil,tag='default')
    raise("key=#{@var.stat.keys}") unless keys
    stat={}
    keys.split(',').each{|k|
      s=@var.stat[k] || raise("No such key[#{k}]")
      stat[k]=s
    }
    @fd.save_stat(stat,tag)
  end

end
