#!/usr/bin/ruby
require "libint"
require "libstatus"
require "libwatch"
require "libfrmlist"
module App
  class Main < Int::Shell
    attr_reader :stat,:fcl
    def initialize(adb)
      @adb=Msg.type?(adb,App::Db)
      super()
      @cobj.add_ext(adb,:command)
      self['id']=adb['id']
      @port=adb['port'].to_i
      @stat=Status::Var.new.ext_watch_r.ext_file(adb)
      @pconv.update({'auto'=>'@','watch'=>'&','isu'=>'*','na'=>'X'})
    end

    def to_s
      @stat.to_s
    end
  end

  class Test < Main
    require "libsymconv"
    def initialize(adb)
      super
      @stat.extend(Sym::Conv).load.extend(Watch::Conv)
      grp=@intcmd.add_group('int',"Internal Command")
      cri={:type => 'reg', :list => ['.']}
      grp.add_item('set','[key=val,...]',[cri]).set_proc{|par|
        par.each{|exp| @stat.str_update(exp).upd}
        "Set #{par}"
      }
    end

    def exe(cmd)
      @stat.set_time
      super||'OK'
    end
  end

  class Sh < Main
    def initialize(adb,fdb,fhost=nil)
      Msg.type?(fdb,Frm::Db)
      super(adb)
      @fcl=Frm::Cl.new(fdb,fhost)
    end
  end


  class Cl < Sh
    def initialize(adb,fdb,host=nil)
      super(adb,fdb,host)
      @host=Msg.type?(host||adb['host']||'localhost',String)
      @stat.ext_url(@host).load
      extend(Int::Client)
    end

    def to_s
      @stat.load.to_s
    end
  end
end
