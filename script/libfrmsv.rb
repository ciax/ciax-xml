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
      @field.ext_rsp(@cobj)
      if Msg.type?(iocmd,Array).empty?
        @io=Stream.new(fdb['iocmd'].split(' '),fdb['wait'],1)
        id=fdb['id'];ver=fdb['frm_ver']
        @io.ext_logging(id,ver)
        @field.ext_sqlog
      else
        @io=Stream.new(iocmd,fdb['wait'],1)
      end
      @cobj['set'].add_proc{|par|
        @field.set(par[0],par[1]).save
      }
      @cobj['unset'].add_proc{|par|
        @field.unset(par.first)
      }
      @cobj['save'].add_proc{|par|
        @field.savekey(par[0].split(','),par[1])
      }
      @cobj['load'].add_proc{|par|
        @field.load(par.first||'')
      }
      @cobj['sleep'].add_proc{|par| sleep par.first.to_i }
      # add_proc is changed from here
      @cobj.ext_frmcmd(@field)
      @cobj.def_proc{|frm,cid|
        @io.snd(frm,cid)
        @field.upd{@io.rcv} && @field.save
      }
      extend(Int::Server)
    rescue Errno::ENOENT
      Msg.warn(" --- no json file")
    end

    #Cmd should be array
    def exe(cmd)
      super||'OK'
    end
  end
end
