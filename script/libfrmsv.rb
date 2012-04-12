#!/usr/bin/ruby
require "libfrmobj"
require "libmsg"
require "libfrmrsp"
require "libstream"
require "libsql"
require "libfrmcmd"

class FrmSv < FrmObj
  def initialize(fdb,iocmd=[])
    super(fdb)
    @v=Msg::Ver.new(self,3)
    @field.extend(Field::IoFile).init(fdb['id']).load
    @fr=FrmRsp.new(fdb,@cobj,@field)
    if Msg.type?(iocmd,Array).empty?
      @io=Stream.new(fdb['iocmd'].split(' '),fdb['wait'],1)
      id=fdb['id'];ver=fdb['frm_ver']
      @io.extend(Stream::Logging).startlog(id,ver)
      @sql=Sql::Logging.new('field',id,ver,@field)
    else
      @io=Stream.new(iocmd,fdb['wait'],1)
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
      unset(cmd[1])
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
      @fr.upd{@io.rcv} && (@sql.upd.flush;@field.save)
    end
    'OK'
  end

  private
  def set(par)
    if par.empty?
      raise UserError,"Usage: set [key(:idx)] (val)\n key=#{@field.keys}"
    end
    @field.set(par[0],par[1]).save
  end

  def unset(par)
    unless par
      raise UserError,"Usage: unset [key(:idx)]\n key=#{@field.keys}"
    end
    @field.delete(par)
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
