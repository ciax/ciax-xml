#!/usr/bin/ruby
require "libinteractive"
require "libstatus"
require "libwatch"

module App
  module Exe
    # @< cobj,output,intgrp,interrupt,upd_proc*
    # @ adb,extdom,watch,stat*
    attr_reader :stat
    def init(adb)
      @adb=Msg.type?(adb,Db)
      @extdom=@cobj.add_extdom(@adb,:command)
      self['id']=@adb['site_id']
      @output=@stat=Status::Var.new.ext_file(@adb['site_id'])
      @watch=Watch::Var.new.ext_file(@adb['site_id'])
      self
    end
  end

  class Test < Interactive::Exe
    require "libsymconv"
    def initialize(adb)
      super()
      extend(Exe).init(adb)
      @stat.ext_sym(adb).load
      @watch.ext_conv(adb,@stat).upd
      cri={:type => 'reg', :list => ['.']}
      @intgrp.add_item('set','[key=val,...]',[cri]).reset_proc{|item|
        @stat.str_update(item.par[0]).upd
        @watch.upd
        self['msg']="Set #{item.par[0]}"
      }
      @intgrp.add_item('del','[key,...]',[cri]).reset_proc{|item|
        item.par[0].split(',').each{|key|
          @stat['val'].delete(key)
        }
        @stat.upd
        @watch.upd
        self['msg']="Delete #{item.par[0]}"
      }
      @interrupt.reset_proc{
        int=@watch.interrupt
        self['msg']="Interrupt #{int}"
      }
      @watch.event_proc=proc{|cmd,p|
        Msg.msg("#{cmd} is issued by event")
      }
      @cobj.def_proc.set{|item|
        @watch.block?(item.cmd)
        @stat.upd
        @watch.upd
      }
      @upd_proc.add{
        @watch.issue
      }
    end
  end

  class Cl < Interactive::Client
    def initialize(adb,host=nil)
      super()
      extend(Exe).init(adb)
      host=Msg.type?(host||adb['host']||'localhost',String)
      @stat.ext_url(host).load
      @watch.ext_url(host).load
      client(host,adb['port'])
      @upd_proc.add{
        @stat.load
        @watch.load
      }
    end
  end
end
