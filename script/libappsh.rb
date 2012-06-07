#!/usr/bin/ruby
require "libint"
require "libstatus"
require "libfrmlist"
module App
  class Sh < Int::Shell
    attr_reader :stat
    def initialize(adb)
      @adb=Msg.type?(adb,App::Db)
      super(Command.new(adb[:command]))
      @prompt['id']=adb['id']
      @port=adb['port'].to_i
      @stat=Status::Var.new.ext_watch_r.ext_file(adb)
      @prompt.table.update({'auto'=>'@','watch'=>'&','isu'=>'*','na'=>'X'})
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

  module Test
    require "libsymconv"
    def self.extended(obj)
      Msg.type?(obj,Sh).init
    end

    def init
      @stat.extend(Sym::Conv).load.extend(Watch::Conv)
      @post_exe << proc{@stat.upd}
      grp=@cobj.add_group('int',"Internal Command")
      grp.add_item('int','set','[key=val,...]'){|par|
        Msg.err("Usage: set [key=val,..]") if par.empty?
        @stat.str_update(par.first).upd
        "Set #{par}"
      }
      self
    end

    def exe(cmd)
      @stat.set_time
      super.exe
      'OK'
    end
  end
end
