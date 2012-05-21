#!/usr/bin/ruby
require "libappsh"
require "libappcmd"
require "libapprsp"
require "libsymconv"
require "libsqlog"
require "libbuffer"
require "thread"

module App
  class Sv < Sh
    attr_reader :fint
    def initialize(adb)
      super(adb)
      id=adb['id']
      @stat.ext_save.extend(App::Rsp).init(@fint.field).extend(Sym::Conv).upd
      @stat.extend(SqLog::Var).extend(SqLog::Exec) if @fint.field.key?('ver')
      @stat.extend(Watch::Conv)
      Thread.abort_on_exception=true
      @buf=Buffer.new.thread{|fcmd| @fint.exe(fcmd) }
      @cobj.extend(App::Cmd).extend(Command::Exe).init{|obj,pri|
        @buf.send(pri){ obj.get }
        "ISSUED"
      }
      @cobj.add_proc('interrupt'){
        int=@stat.interrupt.each{|cmd|
          @cobj.exe(cmd,0)
        }
        "Interrupt #{int}"
      }
      @buf.post_flush << proc{
        @stat.upd.save
        sleep(@stat.interval||0.1)
        @stat.issue.each{|cmd|
          @cobj.exe(cmd,2)
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
      msg=''
      if @stat.block?(cmd)
        msg="Blocking(#{cmd})"
      elsif /OK/ === (msg=super)
        msg=@cobj.exe(cmd,1)
      end
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
      @prompt['isu'] = @buf.issue
      @prompt['na'] = !@buf.alive?
      self
    end

    # ary is bunch of appcmd array (ary of ary)
    def sendfrm(ary,pri=1)
      @buf.send(pri){
        # Making bunch of frmcmd array (ary of ary)
        ary.map{|cmd|
          @cobj.set(cmd).get
        }.flatten(1)
      }
    end

    def auto_update
      @tid=Thread.new{
        Thread.pass
        int=(@stat.period||300).to_i
        cmd=[['upd']]
        loop{
          begin
            sendfrm(cmd,2)
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
