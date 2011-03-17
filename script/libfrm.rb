#!/usr/bin/ruby
require "libiocmd"
require "libiofile"
require "libstat"
require "libfrmcmd"
require "libfrmrsp"

class Frm
  def initialize(doc,id,iocmd)
    raise "Init Param must be XmlDoc" unless XmlDoc === doc
    $errmsg=''
    @stat=Stat.new(id,"field")
    @cmd=FrmCmd.new(doc,@stat)
    @rsp=FrmRsp.new(doc,@stat)
    @v=Verbose.new("fdb/#{id}".upcase)
    @ic=IoCmd.new(iocmd,'device_'+id,doc['wait'],1)
  end

  def field
    Hash[@stat]
  end

  def transaction(stm)
    return if stm.empty?
    @v.msg{"Receive #{stm}"}
    @cmd.setcmd(stm)
    @rsp.setrsp(stm)
    cid=stm.join(':')
    @ic.snd(@cmd.getframe,'snd:'+cid)
    @rsp.getfield(@ic.time){ @ic.rcv('rcv:'+cid) }
    @stat.save
  rescue SelectID
    case stm.shift
    when 'set'
      set(stm).inspect
    when 'load'
      load(stm.shift||'default')
    when 'save'
      save(stm.shift,stm.shift||'default')
    else
      $errmsg << "== Internal Command ==\n"
      $errmsg << " set       : Set Value  [key(:idx)] (val)\n"
      $errmsg << " load      : Load Field (tag)\n"
      $errmsg << " save      : Save Field [key,key...] (tag)\n"
      raise SelectID,$errmsg.slice!(0..-1)
    end
  ensure
    $errmsg.clear
  end

  private
  def set(stm)
    if stm.empty?
      raise "Usage: set [key(:idx)] (val)\n key=#{@stat.keys}"
    end
    @v.msg{"CMD:set#{stm}"}
    @stat.set(stm[0],stm[1])
  end

 
  def save(keys=nil,tag='default')
    unless keys
      raise "Usage: save [key,key..] (tag)\n key=#{@stat.keys}"
    end
    @stat.save(tag,keys.split(','))
  end

  def load(tag='default')
    @stat.load(tag)
  rescue SelectID
    raise "Usage: load (tag)\n #{$!}"
  end
end
