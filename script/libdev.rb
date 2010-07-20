#!/usr/bin/ruby
require "libxmldoc"
require "libiocmd"
require "libiofile"
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
    @rsp=DevRsp.new(@ddb)
    @cmd=DevCmd.new(@ddb)
    @cid=String.new
    @cmdcache=Hash.new
    @fd=IoFile.new("field_#{id}")
    begin
      @field=@fd.load_stat
    rescue
      warn $!
      @field={'device'=>@ddb['id'] }
    end
  end

  def setcmd(cmdary)
    @cid=cmdary.compact.join(':')
    @send=@ddb.select_id('cmdselect',cmdary.shift)
    @v.msg{'Select:'+@send.attributes['label']}
    res=@send.attributes['response']
    @recv= res ? @ddb.select_id('rspselect',res) : nil
    @cmd.par=@rsp.par=cmdary.shift
  end

  def getcmd
    return unless @send
    if cmd=@cmdcache[@cid]
      @v.msg{"Cmd cache found [#{@cid}]"}
      cmd
    else
      @cmdcache[@cid]=@cmd.cmdframe(@send)
    end
  end

  def setrsp(time=Time.now)
    return unless @recv
    @field.update(@rsp.rspframe(@recv){yield})
    @field['time']="%.3f" % time.to_f
    @fd.save_stat(@field)
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
