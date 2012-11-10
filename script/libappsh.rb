#!/usr/bin/ruby
require "libint"
require "libstatus"
require "libwatch"
require "libfrmsh"

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
      @host=Msg.type?(host||adb['host']||'localhost',String)
      @stat.ext_url(@host).load
      ext_client(adb['port'])
    end

    def to_s
      @stat.load.to_s
    end
  end

  class List < Int::List
    def initialize
      $opt||={}
      @fl=Frm::List.new
      @fint={}
      super(){|ldb|
        id=ldb['id']
        if $opt['t']
          aint=App::Test.new(ldb[:app])
        else
          @fint[id]=@fl[ldb[:frm]['site']]
          if $opt['a']
            aint=App::Cl.new(ldb[:app],$opt['h'])
          else
            aint=App::Sv.new(ldb[:app],@fint[id])
          end
        end
        aint
      }
    end

    def shell(id)
      @share_proc.add{|ldb,int|
        int.ext_shell({'auto'=>'@','watch'=>'&','isu'=>'*','na'=>'X'})
        int.set_switch('lay',"Change Layer",{'frm'=>"Frm mode"})
        yield ldb['id'],int if defined? yield
      }
      @fl.share_proc.add{|ldb,int|
        int.set_switch('lay',"Change Layer",{'app'=>"App mode"})
      }
      @type='app'
      @id=id
      super{|cmd|
        case cmd
        when 'app','frm'
          @type=cmd
        else
          @id=cmd
        end
        case @type
        when /app/
          self[@id]
        when /frm/
          @fint[@id]
        end
      }
    end

    def server(ary)
      @share_proc.add{|ldb,int|
        yield ldb['id'],int if defined? yield
      }
      super
    end
  end
end
