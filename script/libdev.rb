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
    return unless @xprecv
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
      load(*par)
    when 'save'
      save(*par)
    else
      begin
        setcmd(cmdary)
      rescue
        msg=["== Command List =="]
        msg << $!.to_s
        msg << "== Data Handling =="
        msg << " set       : Set Value  [key(:index)=val]"
        msg << " load      : Load Field [key] (tag)"
        msg << " save      : Save Field [key] (tag)"
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
    list=[]
    cmdary.each{|e|
      key,val=e.split('=')
      h=@cs.acc_stat(key)
      h.replace(eval(@cs.sub_var(val)).to_s) if val
      list << "#{key}=#{h}"
    }
    list
  end

  def load(key=nil,tag='default')
    @cs.stat.update(@fd.load_stat("_#{key}_#{tag}"))
  end
 
  def save(key=nil,tag='default')
    if stat=@cs.stat[key]
      @fd.save_stat({ key => stat },"_#{key}_#{tag}")
    else
      msg=["== Key List =="]
      msg << " #{@cs.stat.keys}"
      raise msg.join("\n")
    end
  end

end
