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
      @field.ext_save.load
      @field.extend(Frm::Rsp).init(@cobj)
      if Msg.type?(iocmd,Array).empty?
        @io=Stream.new(fdb['iocmd'].split(' '),fdb['wait'],1)
        id=fdb['id'];ver=fdb['frm_ver']
        @io.ext_logging(id,ver)
        @field.extend(SqLog::Var).extend(SqLog::Exec)
      else
        @io=Stream.new(iocmd,fdb['wait'],1)
      end
      @cobj.values.each{|item|
        item.extend(Frm::Cmd).init(fdb,@field)
      }
      @cobj.def_proc{|cid,frm|
        @io.snd(frm,cid)
        @field.upd{@io.rcv} && @field.save
      }
      @cobj['set'].add_proc{|id,par|
        @field.set(par[0],par[1]).save
      }
      @cobj['unset'].add_proc{|id,par|
        @field.unset(par.first)
      }
      @cobj['save'].add_proc{|id,par|
        @field.savekey(par[0].split(','),par[1])
      }
      @cobj['load'].add_proc{|id,par|
        @field.load(par.first||'')
      }
      @cobj['sleep'].add_proc{|id,par| sleep par.first.to_i }
      extend(Int::Server)
    rescue Errno::ENOENT
      Msg.warn(" --- no json file")
    end

    #Cmd should be array
    def exe(cmd)
      @cobj.set(cmd).exe||'OK'
    end
  end
end
