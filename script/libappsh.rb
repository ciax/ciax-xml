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
      @stat=Status::Var.new.extend(Watch::Var).ext_file(adb)
      @prompt.table.update({'auto'=>'@','watch'=>'&','isu'=>'*','na'=>'X'})
      @fint=Frm::List.new[adb['id']]
      @cmdlist.add_group('lay',"Change Layer",{'frm'=>"Frm mode"},2)
      @fint.cmdlist.add_group('lay',"Change Layer",{'app'=>"App mode"},2)
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
      @cobj.extend(Command::Exe).init{'OK'}.add_proc('set','[key=val,...]'){|par|
        Msg.err("Usage: set [key=val,..]") if par.empty?
        @stat.str_update(par.first).upd
        "Set #{par}"
      }
      self
    end

    def exe(cmd)
      if obj=super
        msg=obj.exe
        @stat.set_time unless msg.empty?
      end
      msg
    end
  end
end
