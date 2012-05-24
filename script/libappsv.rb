#!/usr/bin/ruby
require "libappsh"
require "libappcmd"
require "libapprsp"
require "libsymconv"
require "libsqlog"
require "thread"

module App
  class Sv < Sh
    attr_reader :fint
    def initialize(adb)
      super(adb)
      id=adb['id']
      @stat.ext_save.ext_rsp(@fint.field).ext_sym.upd
      @stat.extend(SqLog::Var).extend(SqLog::Exec) if @fint.field.key?('ver')
      @stat.ext_watch_w
      Thread.abort_on_exception=true
      @cobj.extend(App::Cmd).extend(App::Exe)
      @cobj.buf.thread{|fcmd| @fint.exe(fcmd) }
      @cobj.pre_proc{|cmd|
        Msg.err("Blocking(#{cmd})") if @stat.block?(cmd)
      }
      @cobj.add_case('interrupt'){
        int=@stat.interrupt.each{|cmd|
          @cobj.set(cmd).call(0)
        }
        "Interrupt #{int}"
      }
      @cobj.buf.post_flush << proc{
        @stat.upd.save
        sleep(@stat.interval||0.1)
        @stat.issue.each{|cmd|
          @cobj.set(cmd).call(2)
        }
      }
      @fint.post_exe << proc {
        @stat.upd
      }
      # Logging if version number exists
      if @stat.ver
        @cobj.ext_logging(id,@stat.ver){@stat.active}
      end
      auto_update
      upd_prompt
      extend(Int::Server)
    end

    #cmd is array
    def exe(cmd)
      msg=super(cmd).call(1)
      upd_prompt
      msg
    end

    def server(type='app',json=true)
      super
    end

    private
    def upd_prompt
      @prompt['auto'] = @tid && @tid.alive?
      @prompt['watch'] = @stat.active?
      @prompt['isu'] = @cobj.buf.issue
      @prompt['na'] = !@cobj.buf.alive?
      self
    end

    def auto_update
      @tid=Thread.new{
        Thread.pass
        int=(@stat.period||300).to_i
        loop{
          begin
            @cobj.set(['upd']).call(2)
          rescue SelectID
            Msg.warn($!)
          end
          Int::Server.msg{"Auto Update(#{@stat.get('time')})"}
        sleep int
        }
      }
      self
    end
  end
end
