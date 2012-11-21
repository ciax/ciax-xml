#!/usr/bin/ruby
require "libint"
require "libstatus"
require "libwatch"

module App
  class Exe < Int::Exe
    #@< cobj,output,intcmd,int_proc,upd_proc*
    #@ adb,extcmd,output,watch,stat*
    attr_reader :stat
    def initialize(adb)
      @adb=Msg.type?(adb,Db)
      super()
      @extcmd=@cobj.add_ext(@adb,:command)
      self['id']=@adb['site']
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
  end

  class Test < Exe
    require "libsymconv"
    def initialize(adb)
      super
      @stat.extend(Sym::Conv).load
      @watch.ext_conv(adb,@stat).upd
      grp=@intcmd.add_group('int',"Internal Command")
      cri={:type => 'reg', :list => ['.']}
      grp.add_item('set','[key=val,...]',[cri]).init_proc{|item|
        item.par.each{|exp|
          @stat.str_update(exp).upd
          @watch.upd
        }
        self['msg']="Set #{item.par}"
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
      ext_client(host,adb['port'])
      @upd_proc.add{
        @stat.load
        @watch.load
      }
    end
  end
end
