#!/usr/bin/ruby
require "libfrmint"
require "libmsg"
require "libfrmrsp"
require "libstream"
require "libsqlog"
require "libfrmcmd"

module Frm
  class Sv < Int
    def initialize(fdb,iocmd=[])
      super(fdb)
      @field.extend(Frm::Rsp).init(fdb,@cobj)
      @field.extend(Field::IoFile).init(fdb['id']).load
      if Msg.type?(iocmd,Array).empty?
        @io=Stream.new(fdb['iocmd'].split(' '),fdb['wait'],1)
        id=fdb['id'];ver=fdb['frm_ver']
        @io.extend(Stream::Logging).init(id,ver)
        @field.extend(SqLog::Stat).extend(SqLog::Exec)
      else
        @io=Stream.new(iocmd,fdb['wait'],1)
      end
      @fc=Frm::Cmd.new(fdb,@cobj,@field)
    rescue Errno::ENOENT
      Msg.warn(" --- no json file")
    end

    #Cmd should be array
    def exe(cmd)
      Msg.type?(cmd,Array)
      case cmd[0]
      when nil
        return ''
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
        @io.cid=@cobj.set(cmd)[:cid]
        @v.msg{"Issue[#{@io.cid}]"}
        @io.snd(@fc.getframe)
        @field.upd{@io.rcv} && @field.save
      end
      'OK'
    end

    def socket
      super('frm')
    end

    private
    def set(par)
      if par.empty?
        raise UserError,"Usage: set [key(:idx)] (val)\n key=#{@field.val.keys}"
      end
      @field.set(par[0],par[1]).save
    end

    def unset(par)
      unless par
        raise UserError,"Usage: unset [key(:idx)]\n key=#{@field.val.keys}"
      end
      @field.unset(par)
    end

    def save(keys,tag=nil)
      unless keys
        raise UserError,"Usage: save [key,key..] (tag)\n key=#{@field.val.keys}"
      end
      @field.savekey(keys.split(','),tag)
    end

    def load(tag)
      @field.load(tag||'')
    rescue UserError
      raise UserError,"Usage: load (tag)\n #{$!}"
    end
  end
end
