#!/usr/bin/ruby
require "libint"
require "libstatus"
require "libwatch"
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
    require "libfrmsh"
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

  class List < Hash
    require "liblocdb"
    def initialize
      $opt||={}
      super(){|h,id|
        ldb=Loc::Db.new(id)
        adb=ldb.cover_app[:app]
        fdb=ldb.cover_frm[:frm]
        aint=yield id,adb,fdb
        aint.fcl.set_switch('lay',"Change Layer",{'app'=>"App mode"})
        aint.set_switch('lay',"Change Layer",{'frm'=>"Frm mode"})
        aint.set_switch('dev',"Change Device",ldb.list)
        h[id]=aint
      }
    end

    def shell(id)
      type='app'
      while cmd=read(type,id)
        case cmd
        when 'app','frm'
          type=cmd
        else
          id=cmd
        end
      end
    end

    private
    def read(type,id)
      case type
      when /app/
        self[id].shell
      when /frm/
        self[id].fcl.shell
      end
    end
  end
end
