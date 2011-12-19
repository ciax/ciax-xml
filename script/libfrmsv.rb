#!/usr/bin/ruby
require "libfrm"
require "libmsg"
require "libiocmd"
require "libcommand"
require "libfrmrsp"
require "libfrmcmd"
require "libsql"

class FrmSv < Frm
  attr_accessor :updlist
  def initialize(fdb,iocmd=[])
    super(fdb)
    @v=Msg::Ver.new(self,3)
    @field=FrmRsp.new(fdb,@cobj).load
    @updlist=[]
    if Msg.type?(iocmd,Array).empty?
      @io=IoCmd.new(fdb['iocmd'].split(' '),fdb['wait'],1)
      id=fdb['id'];ver=fdb['frm_ver']
      @io.extend(IoLog).startlog(id,ver)
      @sql=SqLog.new('field',id,ver,@field)
      @updlist << proc{ @sql.upd.flush }
    else
      @io=IoCmd.new(iocmd,fdb['wait'],1)
      @field.delete('ver')
    end
    @fc=FrmCmd.new(fdb,@cobj,@field)
    cl=Msg::List.new("Internal Command")
    cl.add('set'=>"Set Value [key(:idx)] (val)")
    cl.add('unset'=>"Remove Value [key]")
    cl.add('load'=>"Load Field (tag)")
    cl.add('save'=>"Save Field [key,key...] (tag)")
    cl.add('sleep'=>"Sleep [n] sec")
    @cobj.list.push(cl)
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
      @io.cid=super[:cid]
      @v.msg{"Issue[#{@io.cid}]"}
      @io.snd(@fc.getframe)
      @field.upd{@io.rcv}.save
      @updlist.each{|p| p.call }
      msg='OK'
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
