#!/usr/bin/ruby
require "libfrmsh"
require "libmsg"
require "libfrmrsp"
require "libstream"
require "libsqlog"
require "libfrmcmd"

module Frm
  class Sv < Sh
    def initialize(fdb,iocmd=[])
      super(fdb)
      @field.ext_file(fdb).ext_save.load
      @field.extend(Frm::Rsp).init(@cobj)
      if Msg.type?(iocmd,Array).empty?
        @io=Stream.new(fdb['iocmd'].split(' '),fdb['wait'],1)
        id=fdb['id'];ver=fdb['frm_ver']
        @io.ext_logging(id,ver)
        @field.extend(SqLog::Var).extend(SqLog::Exec)
      else
        @io=Stream.new(iocmd,fdb['wait'],1)
      end
      @cobj.extend(Frm::Cmd).init(fdb,@field)
      extend(Int::Server)
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
        @io.snd(@cobj.getframe)
        @field.upd{@io.rcv} && @field.save
      end
      'OK'
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
