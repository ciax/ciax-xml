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
        @io.ext_logging(fdb['site'],fdb['version'])
        # @field.ext_sqlog
      else
        @io=Stream.new(iocmd,fdb['wait'],1)
      end
      ext=@cobj.extcmd.ext_frmcmd(@field)
      ext.def_proc << proc{|frm,cid|
        @io.snd(frm,cid)
        @field.upd{@io.rcv} && @field.save
      }
      @cobj['set'].init_proc{|par|
        @field.set(par[0],par[1]).save
      }
      @cobj['unset'].init_proc{|par|
        @field.unset(par.first)
      }
      @cobj['save'].init_proc{|par|
        @field.savekey(par[0].split(','),par[1])
      }
      @cobj['load'].init_proc{|par|
        @field.load(par.first||'')
      }
      ext_server(@port)
    rescue Errno::ENOENT
      Msg.warn(" --- no json file")
    end
  end
end
