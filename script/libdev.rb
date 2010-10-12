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

  def setcmd(line)
    cmdary=line.split(' ').compact
    @cid=cmdary.join(':')
    @send=@ddb.select_id('cmdselect',cmdary.shift)
    a=@send.attributes
    @v.msg{'Select:'+a['label']}
    @nocache=a['nocache']
    res=a['response']
    @recv= res ? @ddb.select_id('rspselect',res) : nil
    @cmd.par=cmdary.clone
    @rsp.par=cmdary
  rescue
    raise "== Command List ==\n#{$!}"
  end

  def getcmd
    return unless @send
    if ! @nocache && cmd=@cmdcache[@cid] 
      @v.msg{"Cmd cache found [#{@cid}]"}
      cmd
    else
      @cmdcache[@cid]=@cmd.cmdframe(@send)
    end
  end

  def setrsp(time=Time.now)
    return unless @recv
    @rsp.rspframe(@recv){yield}
    @cs.stat['time']="%.3f" % time.to_f
    @fd.save_stat(@cs.stat)
  end

  def save(key=nil,tag='default')
    @cs.stat[key] || raise("save #{@cs.stat.keys} [tag]")
    @fd.save_stat({ key => @cs.stat[key] },"_#{key}_#{tag}")
  end

  def load(key=nil,tag='default')
    @cs.stat.update(@fd.load_stat("_#{key}_#{tag}"))
  end

  def setfld(key,val=nil)
    h=@cs.acc_stat(key)
    h.replace(val) if val
    h
  end

end

class DevCom < Dev
  def initialize(dev,iocmd,obj=nil)
    super(dev,obj)
    id=obj||dev
    @ic=IoCmd.new(iocmd,'device_'+id,@ddb['wait'],1)
  end

  def devcom
    @ic.snd(getcmd,'snd:'+@cid)
    frame=@ic.rcv('rcv:'+@cid)
    setrsp(@ic.time){ frame }
  end

end
