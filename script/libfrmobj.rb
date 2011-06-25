#!/usr/bin/ruby
require "libiocmd"
require "libiostat"
require "libfrmcmd"
require "libfrmrsp"

class FrmObj
  attr_reader :interrupt,:prompt
  def initialize(fdb,id,iocmd)
    @field=IoStat.new(id,"field")
    @cmd=FrmCmd.new(fdb,@field)
    @rsp=FrmRsp.new(fdb,@field)
    @v=Verbose.new("fdb/#{id}".upcase)
    @ic=IoCmd.new(iocmd,id,fdb['wait'],1)
    @interupt='',@prompt="#{fdb['id']}>"
    @v.add("== Internal Command ==")
    @v.add('set'=>"Set Value  [key(:idx)] (val)")
    @v.add('unset'=>"Remove Value  [key]")
    @v.add('load'=>"Load Field (tag)")
    @v.add('save'=>"Save Field [key,key...] (tag)")
  end

  def stat
    @field.to_h
  end

  def request(stm)
    return '' if stm.empty?
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
      cid=stm.join(':')
      @ic.snd(@cmd.getframe,'snd:'+cid)
      @rsp.setrsp(stm,@ic.time){ @ic.rcv('rcv:'+cid)||@v.err("No response") }
      @field.save
      'OK'
    end
  rescue SelectID
    @v.list
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
