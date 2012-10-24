#!/usr/bin/ruby
require "libint"
require "libstatus"
require "libwatch"
require "libfrmlist"
module App
  class Sh < Int::Shell
    attr_reader :stat,:fcl
    def initialize(adb,fdb,fhost=nil)
      @adb=Msg.type?(adb,App::Db)
      Msg.type?(fdb,Frm::Db)
      super()
      @cobj.add_ext(adb,:command)
      self['id']=adb['id']
      @port=adb['port'].to_i
      @stat=Status::Var.new.ext_watch_r.ext_file(adb)
      @pconv.update({'auto'=>'@','watch'=>'&','isu'=>'*','na'=>'X'})
      @fcl=Frm::Cl.new(fdb,fhost)
    end

    def to_s
      @stat.to_s
    end
  end

  class Test < Sh
    require "libsymconv"
    def initialize(adb,fdb)
      super(adb,fdb,'localhost')
      @stat.extend(Sym::Conv).load.extend(Watch::Conv)
      grp=@intcmd.add_group('int',"Internal Command")
      cri={:type => 'reg', :list => ['.']}
      grp.add_item('set','[key=val,...]',[cri]).set_proc{|par|
        par.each{|exp| @stat.str_update(exp).upd}
        "Set #{par}"
      }
      self
    end

    def exe(cmd)
      @stat.set_time
      super||'OK'
    end
  end

  class Cl < Sh
    def initialize(adb,fdb,fhost=nil,ahost=nil)
      super(adb,fdb,fhost)
      @host=Msg.type?(ahost||adb['host']||'localhost',String)
      @stat.ext_url(@host).load
      extend(Int::Client)
    end

    def to_s
      @stat.load.to_s
    end
  end
end
