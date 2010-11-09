#!/usr/bin/ruby
require "libxmldoc"
require "libiocmd"
require "libiofile"
require "libstat"
require "libdevcmd"
require "libdevrsp"

class Dev
  def initialize(dev,id,iocmd)
    @ddb=XmlDoc.new('ddb',dev)
  rescue RuntimeError
    abort $!.to_s
  else
    @stat=Stat.new(id,"field")
    @cmd=DevCmd.new(@ddb,@stat)
    @rsp=DevRsp.new(@ddb,@stat)
    @v=Verbose.new("ddb/#{id}".upcase)
    @ic=IoCmd.new(iocmd,'device_'+id,@ddb['wait'],1)
    @stat['sleep']=0
  end

  def field
    Hash[@stat]
  end

  def devcom(stm)
    return if stm.empty?
    @cmd.setcmd(stm)
    @rsp.setrsp(stm)
  rescue SelectID
    case stm.shift
    when 'set'
      set(stm).inspect
    when 'load'
      load(stm.shift||'default')
    when 'save'
      save(stm.shift,stm.shift||'default')
    when 'sleep'
      slp(stm)
    else
      msg=[$!.to_s]
      msg << "== Internal Command =="
      msg << " sleep     : Sleep [sec]"
      msg << " set       : Set Value  [key(:idx)] (val)"
      msg << " load      : Load Field (tag)"
      msg << " save      : Save Field [key,key...] (tag)"
      raise SelectID,msg.join("\n")
    end
  else
    cid=stm.join(':')
    @ic.snd(@cmd.getframe,'snd:'+cid)
    @rsp.getfield(@ic.time){ @ic.rcv('rcv:'+cid) }
    @stat.save
  end

  private
  def slp(stm)
    if stm.empty?
      msg=["  Usage: sleep [sec]"]
      raise SelectID,msg.join("\n")
    end
    s=stm[0]
    @stat['sleep']=1
    @v.msg{"Sleep #{s} sec" }
    sleep s.to_i
    @stat['sleep']=0
  end

  def set(stm)
    if stm.empty?
      msg=["  Usage: set [key(:idx)] (val)"]
      msg << "  key=#{@stat.keys}"
      raise SelectID,msg.join("\n")
    end
    @v.msg{"CMD:set#{stm}"}
    @stat.set(stm[0],stm[1])
  end
 
  def save(keys=nil,tag='default')
    unless keys
      msg=["  Usage: save [key,key..] (tag)"]
      msg << "  key=#{@stat.keys}"
      raise SelectID,msg.join("\n")
    end
    @stat.save(tag,keys.split(','))
  end

  def load(tag='default')
    @stat.load(tag)
  rescue SelectID
    msg=["  Usage: load (tag)"]
    msg << "  #{$!}"
    raise SelectID,msg.join("\n")
  end
end
