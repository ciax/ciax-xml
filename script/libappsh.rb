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
      @cobj.def_proc << proc{|item|
        @stat.block?(item.cmd)
        @stat.set_time.upd.issue
      }
      ext_shell
    end
  end

  module Sh
    def self.extended(obj)
      Msg.type?(obj,Exe)
    end

    def app_shell(fint)
      @fint=Msg.type?(fint,Frm::Exe)
      ext_shell({'auto'=>'@','watch'=>'&','isu'=>'*','na'=>'X'})
      set_switch('lay',"Change Layer",{'frm'=>"Frm mode"})
      @fint.set_switch('lay',"Change Layer",{'app'=>"App mode"})
      self
    end

    def frm_shell
      @fint.shell
    end
  end

  class Cl < Exe
    def initialize(adb,host=nil)
      super(adb)
      @host=Msg.type?(host||adb['host']||'localhost',String)
      @stat.ext_url(@host).load
      ext_client(adb['port'])
    end

    def app_shell(fint)
      extend(Sh).app_shell(fint)
      self
    end

    def to_s
      @stat.load.to_s
    end
  end

  class List < Int::List
    def initialize
      $opt||={}
      @fl=Frm::List.new
      super(){|ldb|
        if $opt['t']
          aint=App::Test.new(ldb[:app])
        else
          fint=@fl[ldb[:frm]['site']]
          if $opt['a']
            aint=App::Cl.new(ldb[:app],$opt['h']).app_shell(fint)
          else
            aint=App::Sv.new(ldb[:app],fint).app_shell
          end
        end
        yield ldb,aint if defined? yield
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
        self[id].frm_shell
      end
    end
  end
end
