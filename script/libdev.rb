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
    @stat=Stat.new("field_#{id}")
    @cmd=DevCmd.new(@ddb,@stat)
    @rsp=DevRsp.new(@ddb,@stat)
    @v=Verbose.new("ddb/#{id}".upcase)
    @ic=IoCmd.new(iocmd,'device_'+id,@ddb['wait'],1)
    @stat['id']=id
  end

  def field
    Hash[@stat]
  end

  def devcom(stm)
    @cmd.setcmd(stm)
    @rsp.setrsp(stm)
  rescue SelectID
    case stm.shift
    when 'set'
      set(stm)
    when 'load'
      @stat.load(stm.shift||'default')
    when 'save'
      save(stm.shift,stm.shift||'default')
    else
      msg=[$!.to_s]
      msg << "== Data Handling =="
      msg << " set       : Set Value  [key(:idx)(=val)]"
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
      msg=["== Option list =="]
      msg << " key(:idx)  : Show Value"
      msg << " key(:idx)= : Set Value"
      msg << " key=#{@stat.keys}"
      raise SelectID,msg.join("\n")
    end
    @v.msg{"CMD:set#{stm}"}
    stat={}
    stm.each{|e|
      key,val=e.split('=')
      h=@stat.acc_stat(key)
      h.replace(eval(@stat.sub_stat(val)).to_s) if val
      stat[key]=@stat[key]
    }
    stat
  end
 
  def save(keys=nil,tag=nil)
    raise("key=#{@stat.keys}") unless keys
    stat={}
    keys.split(',').each{|k|
      s=@stat[k] || raise("No such key[#{k}]")
      stat[k]=s
    }
    @stat.save(stat,tag)
  end
end
