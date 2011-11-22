#!/usr/bin/ruby
require "libfrmint"
require "libmsg"
require "libiocmd"
require "libparam"
require "libfrmrsp"
require "libfrmcmd"

class FrmSv < FrmInt
  def initialize(fdb,iocmd=[])
    super(fdb)
    @v=Msg::Ver.new("frmobj",3)
    client= iocmd.empty? ? fdb['client'].split(' ') : iocmd
    @io=IoCmd.new(client,fdb['wait'],1).extend(IoLog)
    @io.startlog(fdb['id'],fdb['version']) if iocmd.empty?
    @field=FrmRsp.new(fdb,@par)
    @fc=FrmCmd.new(fdb,@par,@field)
    cl=Msg::List.new("Internal Command")
    cl.add('set'=>"Set Value [key(:idx)] (val)")
    cl.add('unset'=>"Remove Value [key]")
    cl.add('load'=>"Load Field (tag)")
    cl.add('save'=>"Save Field [key,key...] (tag)")
    cl.add('sleep'=>"Sleep [n] sec")
    @par.list.push(cl)
    @field.load
  rescue Errno::ENOENT
    Msg.warn(" --- no json file")
  end

  def exe(cmd) #Should be array
    Msg.type?(cmd,Array)
    case cmd[0]
    when nil
      msg=nil
    when 'set'
      msg=set(cmd[1..-1]).inspect
    when 'unset'
      msg=@field.delete(cmd[1]).inspect
    when 'load'
      msg=load(cmd[1])
    when 'save'
      msg=save(cmd[1],cmd[2])
    when 'sleep'
      msg='Done'
      sleep cmd[1].to_i
    else
      msg=super
      cid=@par[:cid]
      @v.msg{"Issue[#{cid}]"}
      @io.snd(@fc.getframe,cid)
      @field.upd{@io.rcv(cid)}.save
    end
    msg
  end

  private
  def set(par)
    if par.empty?
      raise UserError,"Usage: set [key(:idx)] (val)\n key=#{@field.keys}"
    end
    case par[0]
    when /:/
      @field.set(par[0],par[1])
    else
      @field[par[0]]=@field.subst(par[1])
    end
    "[#{par}] set\n"
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
