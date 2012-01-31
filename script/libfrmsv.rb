#!/usr/bin/ruby
require "libfrmobj"
require "libmsg"
require "libfrmrsp"
require "libiocmd"
require "libsql"
require "libfrmcmd"

class FrmSv < FrmObj
  def initialize(fdb,iocmd=[])
    super(fdb)
    @v=Msg::Ver.new(self,3)
    @field=FrmRsp.new(fdb,@cobj).load
    @updlist=@field.updlist
    if Msg.type?(iocmd,Array).empty?
      @io=IoCmd.new(fdb['iocmd'].split(' '),fdb['wait'],1)
      id=fdb['id'];ver=fdb['frm_ver']
      @io.extend(IoLog).startlog(id,ver)
      @sql=SqLog.new('field',id,ver,@field)
      @field.updlist << proc{ @sql.upd.flush }
    else
      @io=IoCmd.new(iocmd,fdb['wait'],1)
      @field.delete('ver')
    end
    @fc=FrmCmd.new(fdb,@cobj,@field)
  rescue Errno::ENOENT
    Msg.warn(" --- no json file")
  end

  #Cmd should be array
  def exe(cmd)
    Msg.type?(cmd,Array)
    case cmd[0]
    when nil
      return
    when 'set'
      set(cmd[1..-1])
    when 'unset'
      @field.delete(cmd[1])
    when 'load'
      load(cmd[1])
    when 'save'
      save(cmd[1],cmd[2])
    when 'sleep'
      sleep cmd[1].to_i
    else
      @io.cid=super[:cid]
      @v.msg{"Issue[#{@io.cid}]"}
      @io.snd(@fc.getframe)
      @field.upd{@io.rcv}.save
    end
    'OK'
  end

  private
  def set(par)
    if par.empty?
      raise UserError,"Usage: set [key(:idx)] (val)\n key=#{@field.keys}"
    end
    @field.set(par[0],par[1])
  end

  def save(keys,tag=nil)
    unless keys
      raise UserError,"Usage: save [key,key..] (tag)\n key=#{@field.keys}"
    end
    @field.savekey(keys.split(','),tag)
  end

  def load(tag)
    tag='' unless tag
    @field.loadkey(tag)
  rescue UserError
    raise UserError,"Usage: load (tag)\n #{$!}"
  end
end
