#!/usr/bin/ruby
require "libappsh"
require "libappcmd"
require "libapprsp"
require "libsymconv"
require "libbuffer"
require "thread"

module App
  class Sv < Sh
    attr_reader :fint
    def initialize(adb)
      super(adb)
      id=adb['id']
      @cobj.extend(App::Cmd)
      @stat.ext_save.extend(App::Rsp).init(@fint.field).upd
      @stat.extend(SqLog::Var).extend(SqLog::Exec) if @fint.field.key?('ver')
      @stat.extend(Watch::Conv)
      Thread.abort_on_exception=true
      @buf=Buffer.new.thread{|fcmd| @fint.exe(fcmd) }
      @buf.post_flush << proc{
        @stat.upd.save
        sleep(@stat.interval||0.1)
        sendfrm(@stat.issue,2)
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
      elsif /interrupt/ === cmd[0]
        int=@stat.interrupt
        sendfrm(int,0)
        msg="Interrupt #{int}"
      elsif /OK/ === (msg=super)
        sendfrm([cmd])
        msg="ISSUED"
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
