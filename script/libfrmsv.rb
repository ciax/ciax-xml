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
      ext.def_proc << proc{|item|
        @io.snd(item.getframe,item[:cid])
        @field.upd{@io.rcv} && @field.save
      }
      @cobj['set'].init_proc{|item|
        @field.set(item.par[0],item.par[1]).save
      }
      @cobj['unset'].init_proc{|item|
        @field.unset(item.par[0]).save
      }
      @cobj['save'].init_proc{|item|
        @field.savekey(item.par[0].split(','),item.par[1])
      }
      @cobj['load'].init_proc{|item|
        @field.load(item.par[0]||'').save
      }
      ext_server(@port)
    rescue Errno::ENOENT
      Msg.warn(" --- no json file")
    end
  end
end
