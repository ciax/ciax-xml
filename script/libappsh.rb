#!/usr/bin/ruby
require "libint"
require "libstatus"
require "libfrmlist"
module App
  class Sh < Int::Shell
    attr_reader :stat
    def initialize(adb)
      @adb=Msg.type?(adb,App::Db)
      super()
      @cobj.add_ext(adb,:command)
      self['id']=adb['id']
      @port=adb['port'].to_i
      @stat=Status::Var.new.ext_watch_r.ext_file(adb)
      @pconv.update({'auto'=>'@','watch'=>'&','isu'=>'*','na'=>'X'})
      @fint=Frm::List.new[adb['id']]
      set_switch('lay',"Change Layer",{'frm'=>"Frm mode"})
      @fint.set_switch('lay',"Change Layer",{'app'=>"App mode"})
      @shmode='app'
    end

    def shell
      id=@shmode
      loop{
        case id
        when /app/
          @shmode=id
          id=super||break
        when /frm/
          @shmode=id
          id=@fint.shell||break
        else
          break id
        end
      }
    end

    def to_s
      @stat.to_s
    end
  end

  class Test < Sh
    require "libsymconv"
    def initialize(adb)
      super
      @stat.extend(Sym::Conv).load.extend(Watch::Conv)
      grp=@cobj.int.add_group('int',"Internal Command")
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
    def initialize(adb,host=nil)
      super(adb)
      host||=adb['host']
      @host=Msg.type?(host||adb['host'],String)
      @stat.ext_url(@host).load
      extend(Int::Client)
    end

    def to_s
      @stat.load.to_s
    end
  end
end
