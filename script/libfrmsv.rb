#!/usr/bin/ruby
require "libfrmexe"
require "libfrmrsp"
require "libfrmcmd"

module Frm
  class Sv < Interactive::Server
    # @<< cobj,(output),(intgrp),(interrupt),(upd_proc*)
    # @< extdom,field*
    # @ io
    def initialize(fdb,iocmd=[])
      super()
      extend(Exe).init(fdb)
      @field.ext_save.load
      @field.ext_rsp(@cobj,fdb)
      if Msg.type?(iocmd,Array).empty?
        @io=Stream.new(fdb['iocmd'].split(' '),fdb['wait'],1)
        @io.ext_logging(fdb['site_id'],fdb['version'])
        # @field.ext_sqlog
      else
        @io=Stream.new(iocmd,fdb['wait'],1)
      end
      @extdom.ext_frmcmd(@field,fdb).reset_proc{|item|
        @io.snd(item.getframe,item[:cmd])
        @field.upd{@io.rcv} && @field.save
      }
      @cobj['set'].reset_proc{|item|
        @field.set(item.par[0],item.par[1]).save
      }
      @cobj['save'].reset_proc{|item|
        @field.savekey(item.par[0].split(','),item.par[1])
      }
      @cobj['load'].reset_proc{|item|
        @field.load(item.par[0]||'').save
      }
      server(fdb['port'].to_i)
    rescue Errno::ENOENT
      Msg.warn(" --- no json file")
    end
  end
end
