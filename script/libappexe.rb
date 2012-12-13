#!/usr/bin/ruby
require "libint"
require "libstatus"
require "libwatch"

module App
  class Exe < Int::Exe
    # @< cobj,output,intdom,int_proc,upd_proc*
    # @ adb,extdom,intgrp,output,watch,stat*
    attr_reader :stat
    def initialize(adb)
      @adb=Msg.type?(adb,Db)
      super()
      @extdom=@cobj.add_extdom(@adb,:command)
      @intgrp=@intdom.add_group('int',"Internal Command")
      @intgrp.add_item('interrupt')
      self['id']=@adb['site_id']
      @output=@stat=Status::Var.new.ext_file(@adb)
      @watch=Watch::Var.new.ext_file(@adb)
    end

    def exe(cmd)
      super
      while self['isu']
        @upd_proc.upd
      end
      self
    end

    def interrupt
      @cobj['interrupt'].exe
      self
    end
  end

  class Test < Exe
    require "libsymconv"
    def initialize(adb)
      super
      @stat.extend(Sym::Conv).load
      @watch.ext_conv(adb,@stat).upd
      cri={:type => 'reg', :list => ['.']}
      @intgrp.add_item('set','[key=val,...]',[cri]).init_proc{|item|
        @stat.str_update(item.par[0]).upd
        @watch.upd
        self['msg']="Set #{item.par[0]}"
      }
      @intgrp.add_item('del','[key,...]',[cri]).init_proc{|item|
        item.par[0].split(',').each{|key|
          @stat['val'].delete(key)
        }
        @stat.upd
        @watch.upd
        self['msg']="Delete #{item.par[0]}"
      }
      @cobj['interrupt'].init_proc{
        int=@watch.interrupt
        self['msg']="Interrupt #{int}"
      }
      @watch.event_proc.add{|cmd,p|
        Msg.msg("#{cmd} is issued by event")
      }
      @cobj.def_proc.add{|item|
        @watch.block?(item.cmd)
        @stat.set_time.upd
        @watch.upd
      }
      @upd_proc.add{
        @watch.issue
      }
    end
  end

  class Cl < Exe
    def initialize(adb,host=nil)
      super(adb)
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
