#!/usr/bin/ruby
require "libiocmd"
require "libiostat"
require "libfrmcmd"
require "libfrmrsp"

class Frm
  attr_reader :interrupt,:prompt
  def initialize(fdb,id,iocmd)
    @field=IoStat.new(id,"field")
    @cmd=FrmCmd.new(fdb,@field)
    @rsp=FrmRsp.new(fdb,@field)
    @v=Verbose.new("fdb/#{id}".upcase)
    @ic=IoCmd.new(iocmd,id,fdb['wait'],1)
    @interupt='',@prompt="#{fdb['id']}>"
  end

  def stat
    @field.to_h
  end

  def request(stm)
    return self if stm.empty?
    @v.msg{"Receive #{stm}"}
    case stm[0]
    when 'set'
      set(stm[1..-1]).inspect
    when 'unset'
      @field.delete(stm[1]).inspect
    when 'load'
      load(stm[1])
    when 'save'
      save(stm[1],stm[2])
    else
      @cmd.setcmd(stm)
      @rsp.setrsp(stm)
      cid=stm.join(':')
      @ic.snd(@cmd.getframe,'snd:'+cid)
      @rsp.getfield(@ic.time){ @ic.rcv('rcv:'+cid)||@v.err("No response") }
      @field.save
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
      raise UserError,"Usage: set [key(:idx)] (val)\n key=#{@field.keys}"
    end
    @v.msg{"CMD:set#{stm}"}
    case stm[0]
    when /:/
      @field.set(stm[0],stm[1])
    else
      @field[stm[0]]=@field.subst(stm[1])
    end
    "[#{stm}] set\n"
  end

  def save(keys,tag=nil)
    unless keys
      raise UserError,"Usage: save [key,key..] (tag)\n key=#{@field.keys}"
    end
    tag=Time.now.strftime('%y%m%d-%H%M%S') unless tag
    @field.save(tag,keys.split(','))
    "[#{tag}] saved\n"
  end

  def load(tag)
    tag='' unless tag
    @field.load(tag)
    "[#{tag}] loaded"
  rescue SelectID
    raise "Usage: load (tag)\n #{$!}"
  end
end
