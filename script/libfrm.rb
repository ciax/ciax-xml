#!/usr/bin/ruby
require "libiocmd"
require "libstat"
require "libfrmcmd"
require "libfrmrsp"

class Frm
  attr_reader :interrupt,:prompt
  def initialize(doc,id,iocmd)
    raise "Init Param must be XmlDoc" unless XmlDoc === doc
    @stat=Stat.new(id,"field")
    @cmd=FrmCmd.new(doc,@stat)
    @rsp=FrmRsp.new(doc,@stat)
    @v=Verbose.new("fdb/#{id}".upcase)
    @ic=IoCmd.new(iocmd,'device_'+id,doc['wait'],1)
    @interupt='',@prompt="#{doc['id']}>"
  end

  def field
    Hash[@stat]
  end

  def quit
    @stat.save
  end

  def transaction(stm)
    return self if stm.empty?
    @v.msg{"Receive #{stm}"}
    @cmd.setcmd(stm)
    @rsp.setrsp(stm)
    cid=stm.join(':')
    @ic.snd(@cmd.getframe,'snd:'+cid)
    @rsp.getfield(@ic.time){ @ic.rcv('rcv:'+cid) }
    self
  rescue SelectID
    case stm.shift
    when 'set'
      set(stm).inspect
    when 'load'
      load(stm.shift||'default')
    when 'save'
      save(stm.shift,stm.shift||'default')
    else
      err="#{$!}"
      err << "== Internal Command ==\n"
      err << " set       : Set Value  [key(:idx)] (val)\n"
      err << " load      : Load Field (tag)\n"
      err << " save      : Save Field [key,key...] (tag)\n"
      raise SelectID,err
    end
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
