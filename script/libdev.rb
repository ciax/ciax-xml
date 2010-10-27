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
      @stat.load(stm.shift||'default')
    when 'save'
      save(stm.shift,stm.shift||'default')
    else
      msg=[$!.to_s]
      msg << "== Data Handling =="
      msg << " set       : Set Value  [key(:idx)] (val)"
      msg << " load      : Load Field (tag)"
      msg << " save      : Save Field [key,key...] (tag)"
      raise SelectID,msg.join("\n")
    end
  else
    cid=stm.join(':')
    @ic.snd(@cmd.getframe,'snd:'+cid)
    @rsp.getfield(@ic.time){ @ic.rcv('rcv:'+cid) }
    @stat.save_all
  end

  def set(stm)
    if stm.empty?
      msg=["  Usage: set [key(:idx)] (val)"]
      msg << "  key=#{@stat.keys}"
      raise SelectID,msg.join("\n")
    end
    @v.msg{"CMD:set#{stm}"}
    @stat.set_stat(stm[0],stm[1])
  end
 
  def save(keys=nil,tag=nil)
    unless keys
      msg=["  Usage: save [key,key..] (tag)"]
      msg << "  key=#{@stat.keys}"
      raise SelectID,msg.join("\n")
    end
    stat={}
    keys.split(',').each{|k|
      stat[k]=@stat[k] || raise("No such key[#{k}]")
    }
    @stat.save(stat,tag)
  end
end
