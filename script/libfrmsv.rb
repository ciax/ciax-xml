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
        item.extend(Frm::Cmd).init(fdb,@field){|cid,frm|
          @io.snd(frm,cid)
          @field.upd{@io.rcv} && @field.save
        }
      }
      @cobj['set'].set_proc{|par|
        @field.set(par[0],par[1]).save
      }
      @cobj['unset'].set_proc{|par|
        @field.unset(par.first)
      }
      @cobj['save'].set_proc{|par|
        @field.savekey(par[0].split(','),par[1])
      }
      @cobj['load'].set_proc{|par|
        begin
          @field.load(par.first||'')
        rescue UserError
          Msg.err("No such tag",$!)
        end
      }
      @cobj['sleep'].set_proc{|par| sleep par.first.to_i }
      extend(Int::Server)
    rescue Errno::ENOENT
      Msg.warn(" --- no json file")
    end

    #Cmd should be array
    def exe(cmd)
      super.exe.call
      'OK'
    end
  end
end
