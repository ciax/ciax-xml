#!/usr/bin/ruby
require "libmsg"
require "libiocmd"
require "libparam"
require "libfrmrsp"
require "libfrmcmd"

class FrmObj
  attr_reader :field,:message
  def initialize(fdb,iocmd=[])
    @v=Msg::Ver.new("frmobj",3)
    Msg.type?(fdb,FrmDb)
    client= iocmd.empty? ? fdb['client'].split(' ') : iocmd
    @io=IoCmd.new(client,fdb['wait'],1).extend(IoLog)
    @io.startlog(fdb['id'],fdb['version']) if iocmd.empty?
    @par=Param.new(fdb[:cmdframe])
    @fr=FrmRsp.new(fdb,@par)
    @field=@fr.field
    @fc=FrmCmd.new(fdb,@par,@field)
    @cl=Msg::List.new("== Internal Command ==")
    @cl.add('set'=>"Set Value  [key(:idx)] (val)")
    @cl.add('unset'=>"Remove Value  [key]")
    @cl.add('load'=>"Load Field (tag)")
    @cl.add('save'=>"Save Field [key,key...] (tag)")
    @field.load
  rescue Errno::ENOENT
    Msg.warn(" --- no json file")
  end

  def upd(cmd) #Should be array
    Msg.type?(cmd,Array)
    @v.msg{"Receive #{cmd}"}
    case cmd[0]
    when nil
      @message=nil
    when 'set'
      @message=set(cmd[1..-1]).inspect
    when 'unset'
      @message=@field.delete(cmd[1]).inspect
    when 'load'
      @message=load(cmd[1])
    when 'save'
      @message=save(cmd[1],cmd[2])
    else
      cid=@par.set(cmd)[:cid]
      @io.snd(@fc.getframe,cid)
      @fr.upd{@io.rcv(cid)}
      @fr.field.save
      @message='OK'
    end
    self
  rescue SelectCMD
    @cl.error
  end

  private
  def set(cmd)
    if cmd.empty?
      raise UserError,"Usage: set [key(:idx)] (val)\n key=#{@field.keys}"
    end
    @v.msg{"CMD:set#{cmd}"}
    case cmd[0]
    when /:/
      @field.set(cmd[0],cmd[1])
    else
      @field[cmd[0]]=@field.subst(cmd[1])
    end
    "[#{cmd}] set\n"
  end

  def save(keys,tag=nil)
    unless keys
      raise UserError,"Usage: save [key,key..] (tag)\n key=#{@field.keys}"
    end
    @field.savekey(keys.split(','),tag)
    tag="[#{tag}]" if tag
    "#{tag}(#{keys}) saved\n"
  end

  def load(tag)
    tag='' unless tag
    @field.loadkey(tag)
    "[#{tag}] loaded"
  rescue UserError
    raise UserError,"Usage: load (tag)\n #{$!}"
  end
end
