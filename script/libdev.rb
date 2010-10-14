#!/usr/bin/ruby
require "libxmldoc"
require "libiocmd"
require "libiofile"
require "libconvstr"
require "libdevcmd"
require "libdevrsp"

# Main
class Dev
  attr_reader :cid,:field

  def initialize(dev,obj=nil)
    @ddb=XmlDoc.new('ddb',dev)
  rescue RuntimeError
    abort $!.to_s
  else
    id=obj||dev
    @v=Verbose.new("ddb/#{id}".upcase)
    @cid=String.new
    @cmdcache=Hash.new
    @fd=IoFile.new("field_#{id}")
    @cs=ConvStr.new(@v)
    @rsp=DevRsp.new(@ddb,@cs)
    @cmd=DevCmd.new(@ddb,@cs)
    begin
      @cs.stat=@fd.load_stat
    rescue
      warn $!
      @rsp.init_field{"0"}
      @cs.stat['device']=@ddb['id']
    end
    @field=@cs.stat
  end

  def setcmd(cmdary)
    @cid=cmdary.join(':')
    cmd=cmdary.shift
    @xpsend=@ddb.select_id('cmdselect',cmd)
    a=@xpsend.attributes
    @v.msg{'Select:'+a['label']}
    res=a['response']
    @xprecv= res ? @ddb.select_id('rspselect',res) : nil
    @cmd.par=cmdary.clone
    @rsp.par=cmdary
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
    @cs.stat['time']="%.3f" % time.to_f
    @fd.save_stat(@cs.stat)
  end

end

class DevCom < Dev
  def initialize(dev,iocmd,obj=nil)
    super(dev,obj)
    id=obj||dev
    @ic=IoCmd.new(iocmd,'device_'+id,@ddb['wait'],1)
  end

  def devcom(line)
    cmdary=line.split(' ').compact
    par=cmdary.dup
    case par.shift
    when 'set'
      set(par)
    when 'load'
      load(par.shift)
    when 'save'
      save(*par)
    else
      begin
        setcmd(cmdary)
      rescue
        msg=["== Command List =="]
        msg << $!.to_s
        msg << "== Data Handling =="
        msg << " set       : Set Value  [key(:idx)(=val)] ..."
        msg << " load      : Load Field (tag)"
        msg << " save      : Save Field [key,key...] (tag)"
        raise msg.join("\n")
      end
      @ic.snd(getcmd,'snd:'+@cid)
      setrsp(@ic.time){ @ic.rcv('rcv:'+@cid) }
    end
  end

  def set(cmdary)
    if cmdary.empty?
      msg=["== option list =="]
      msg << " key(:idx)  : Show Value"
      msg << " key(:idx)= : Set Value"
      msg << " key=#{@cs.stat.keys}"
      raise msg.join("\n")
    end
    @v.msg{"CMD:set[#{cmdary}]"}
    stat={}
    cmdary.each{|e|
      key,val=e.split('=')
      h=@cs.acc_stat(key)
      h.replace(eval(@cs.sub_var(val)).to_s) if val
      stat[key]=@cs.stat[key]
    }
    stat
  end

  def load(tag)
    @cs.stat.update(@fd.load_stat(tag))
  end
 
  def save(keys=nil,tag='default')
    raise("key=#{@cs.stat.keys}") unless keys
    stat={}
    keys.split(',').each{|k|
      s=@cs.stat[k] || raise("No such key[#{k}]")
      stat[k]=s
    }
    @fd.save_stat(stat,tag)
  end

end
