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
      @cmdlist.add_group('int',"Internal Command",{'set'=>"[key=val], .."},2)
      @stat.extend(Sym::Conv).load
      @post_exe << proc{@stat.upd}
      self
    end

    def exe(cmd)
      case cmd.first
      when 'set'
        cmd[1] || raise(UserError,"usage: set [key=val,..]")
        @stat.str_update(cmd[1]).upd
        "Set #{cmd[1]}"
      else
        msg=super
        @stat.set_time unless msg.empty?
        msg
      end
    end
  end
end
