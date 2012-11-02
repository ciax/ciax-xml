#!/usr/bin/ruby
require "libint"
require "libstatus"
require "libwatch"
module App
  class Main < Int::Shell
    attr_reader :stat,:fint
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
      @stat.extend(Sym::Conv).load.extend(Watch::Conv).upd
      grp=@intcmd.add_group('int',"Internal Command")
      cri={:type => 'reg', :list => ['.']}
      grp.add_item('set','[key=val,...]',[cri]).init_proc{|item|
        item.par.each{|exp| @stat.str_update(exp).upd}
        "Set #{item.par}"
      }
      @stat.event_proc=proc{|cmd|
        Msg.msg("#{cmd} is issued by event")
      }
      @cobj.def_proc << proc{|item|
        @stat.block?(item.cmd)
        @stat.set_time.upd.issue
      }
    end
  end

  class Sh < Main
    require "libfrmsh"
    def initialize(ldb,fint)
      @fint=Msg.type?(fint,Frm::Sh)
      super(ldb[:app])
    end
  end


  class Cl < Sh
    def initialize(ldb,host=nil)
      super(ldb,Frm::Cl.new(ldb[:frm],host))
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
      @fl=Frm::List.new{|fdb|
        par=$opt['l'] ? ['frmsim',fdb['site']] : []
        Frm::Sv.new(fdb,par)
      }
      super(){|ldb|
        aint=yield ldb,@fl
        if aint.is_a? App::Sh
          aint.fint.set_switch('lay',"Change Layer",{'app'=>"App mode"})
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
        self[id].fint.shell
      end
    end
  end
end
