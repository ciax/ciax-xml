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
      self['id']=adb['site']
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
      grp.add_item('set','[key=val,...]',[cri]).init_proc{|item|
        item.par.each{|exp| @stat.str_update(exp).upd}
        "Set #{item.par}"
      }
      @cobj.add_def_proc{@stat.set_time}
    end
  end

  class Sh < Main
    require "libfrmsh"
    def initialize(ldb,fhost=nil)
      fdb=Msg.type?(ldb[:frm],Frm::Db)
      super(ldb[:app])
      @fcl=Frm::Cl.new(fdb,fhost)
    end
  end


  class Cl < Sh
    def initialize(ldb,host=nil)
      super
      @host=Msg.type?(host||ldb[:app]['host']||'localhost',String)
      @stat.ext_url(@host).load
      extend(Int::Client)
    end

    def to_s
      @stat.load.to_s
    end
  end

  class List < Int::List
    def initialize
      $opt||={}
      @fsv=Frm::List.new{|fdb|
        par=$opt['l'] ? ['frmsim',fdb['site']] : []
        Frm::Sv.new(fdb,par)
      }
      super(){|ldb|
        aint=yield ldb,@fsv
        if aint.is_a? App::Sh
          aint.fcl.set_switch('lay',"Change Layer",{'app'=>"App mode"})
          aint.set_switch('lay',"Change Layer",{'frm'=>"Frm mode"})
        end
        aint
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
    rescue UserError
      Msg.usage('(opt) [id] ....',*$optlist)
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
