#!/usr/bin/ruby
require "libint"
require "libstatus"
require "libwatch"

module App
  class Exe < Int::Exe
    attr_reader :stat
    def initialize(adb)
      @adb=Msg.type?(adb,Db)
      super()
      @extcmd=@cobj.add_ext(@adb,:command)
      self['id']=@adb['site']
      @port=@adb['port'].to_i
      @stat=Status::Var.new.ext_watch_r.ext_file(@adb)
    end

    def exe(cmd)
      super
      while self['isu']
        @upd_proc.upd
      end
      self
    end

    def to_s
      @stat.to_s
    end
  end

  class Test < Exe
    require "libsymconv"
    def initialize(adb)
      super
      @stat.extend(Sym::Conv).load.extend(Watch::Conv).upd
      grp=@intcmd.add_group('int',"Internal Command")
      cri={:type => 'reg', :list => ['.']}
      grp.add_item('set','[key=val,...]',[cri]).init_proc{|item|
        item.par.each{|exp|
          @stat.str_update(exp).upd
        }
        self['msg']="Set #{item.par}"
      }
      @stat.event_proc=proc{|cmd|
        Msg.msg("#{cmd} is issued by event")
      }
      @cobj.def_proc.add{|item|
        @stat.block?(item.cmd)
        @stat.set_time.upd.issue
      }
    end
  end

  class Cl < Exe
    def initialize(adb,host=nil)
      super(adb)
      host=Msg.type?(host||adb['host']||'localhost',String)
      @stat.ext_url(host).load
      ext_client(host,adb['port'])
    end

    def to_s
      @stat.load.to_s
    end
  end
end
