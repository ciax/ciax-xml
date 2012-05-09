#!/usr/bin/ruby
require "libappint"
require "libappcmd"
require "libapprsp"
require "libsymconv"
require "libbuffer"
require "thread"

module App
  class Sv < Int
    include Server
    attr_reader :fint
    def initialize(adb)
      super(adb)
      id=adb['id']
      @ac=App::Cmd.new(@cobj)
      @stat.extend(App::Rsp).init(adb,@fint.field).upd
      @stat.extend(Sym::Conv).init(adb).ext_iofile
      @stat.extend(SqLog::Stat).extend(SqLog::Exec) if @fint.field.key?('ver')
      @stat.extend(Watch::Conv).init(adb)
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
    end

    #cmd is array
    def exe(cmd)
      msg=''
      case cmd.first
      when nil
      when 'interrupt'
        int=@stat.interrupt
        sendfrm(int,0)
        msg="Interrupt #{int}"
      when 'flush'
        @fint.field.load
        @buf.post_flush.upd
      when 'set'
        cmd[1] || raise(UserError,"usage: set [key=val,..]")
        @stat.str_update(cmd[1]).upd
        msg="Set #{cmd[1]}"
      else
        if @stat.block?(cmd)
          msg="Blocking(#{cmd})"
        else
          sendfrm([cmd])
          msg="ISSUED"
        end
      end
      upd_prompt
      msg
    end

    def socket(type='app',json=true)
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
        @cobj.set(cmd)
        @ac.get
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
        @v.msg{"Auto Update(#{@stat.get('time')})"}
        sleep int
        }
      }
      self
    end
  end
end
