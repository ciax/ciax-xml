#!/usr/bin/ruby
require "libiocmd"
require "libstat"
require "libfrmcmd"
require "libfrmrsp"

class Frm
  attr_reader :interrupt,:prompt
  def initialize(fdb,id,iocmd)
    @stat=Stat.new(id,"field")
    @cmd=FrmCmd.new(fdb,@stat)
    @rsp=FrmRsp.new(fdb,@stat)
    @v=Verbose.new("fdb/#{id}".upcase)
    @ic=IoCmd.new(iocmd,'device_'+id,fdb['wait'],1)
    @interupt='',@prompt="#{fdb['id']}>"
  end

  def stat
    @stat.to_h
  end

  def quit
    @stat.save
  end

  def request(stm)
    return self if stm.empty?
    @v.msg{"Receive #{stm}"}
    case stm[0]
    when 'set'
      set(stm[1..-1]).inspect
    when 'unset'
      @stat.delete(stm[1]).inspect
    when 'load'
      load(stm[1])
    when 'save'
      save(stm[1],stm[2])
    else
      @cmd.setcmd(stm)
      @rsp.setrsp(stm)
      cid=stm.join(':')
      @ic.snd(@cmd.getframe,'snd:'+cid)
      @rsp.getfield(@ic.time){ @ic.rcv('rcv:'+cid) }
      'OK'
    end
  rescue SelectID
    list={}
    list['set']="Set Value  [key(:idx)] (val)"
    list['unset']="Remove Value  [key]"
    list['load']="Load Field (tag)"
    list['save']="Save Field [key,key...] (tag)"
    @v.list(list,"== Internal Command ==")
  end

  private
  def set(stm)
    if stm.empty?
      raise "Usage: set [key(:idx)] (val)\n key=#{@stat.keys}"
    end
    @v.msg{"CMD:set#{stm}"}
    case stm[0]
    when /:/
      @stat.set(stm[0],stm[1])
    else
      @stat[stm[0]]=@stat.subst(stm[1])
    end
    "[#{stm}] set\n"
  end

  def save(keys,tag=nil)
    unless keys
      raise "Usage: save [key,key..] (tag)\n key=#{@stat.keys}"
    end
    tag=Time.now.strftime('%y%m%d-%H%M%S') unless tag
    @stat.save(tag,keys.split(','))
    "[#{tag}] saved\n"
  end

  def load(tag)
    tag='' unless tag
    @stat.load(tag)
    "[#{tag}] loaded"
  rescue SelectID
    raise "Usage: load (tag)\n #{$!}"
  end
end
