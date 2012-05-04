#!/usr/bin/ruby
require "libappint"
require "libappcmd"
require "libappval"
require "libbuffer"
require "thread"

module App
  class Sv < Int
    attr_reader :fint
    def initialize(adb)
      super(adb)
      id=adb['id']
      @ac=App::Cmd.new(@cobj)
      val=App::Val.new(adb,@fint.field).upd
      @stat.extend(Stat::SymConv).init(adb,val)
      @stat.extend(Stat::SqLog) if @fint.field.key?('ver')
      @watch.extend(Watch::Conv).init(adb,val).extend(IoFile).init(id)
      val.post_upd << proc{@stat.upd.save}
      @stat.post_upd << proc{@watch.upd}
      @stat.post_save << proc{@watch.save}
      Thread.abort_on_exception=true
      @buf=Buffer.new.thread{|fcmd| @fint.exe(fcmd) }
      @buf.post_flush << proc{
        val.upd
        sleep(@watch.interval||0.1)
        sendfrm(@watch.issue,2)
      }
      @fint.post_exe << proc {
        val.upd
      }
      # Logging if version number exists
      @cobj.extend(Command::Logging).init(id,@stat.ver){@watch.active} if @stat.ver
      auto_update
      upd_prompt
    end

    #cmd is array
    def exe(cmd)
      msg=''
      case cmd.first
      when nil
      when 'interrupt'
        int=@watch.interrupt
        sendfrm(int,0)
        msg="Interrupt #{int}"
      when 'flush'
        @fint.field.load
        @buf.post_flush.upd
      when 'set'
        cmd[1] || raise(UserError,"usage: set [key=val,..]")
        @stat.str_update(cmd[1]).upd.save
        msg="Set #{cmd[1]}"
      else
        if @watch.block?(cmd)
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
      @prompt['watch'] = @watch.active?
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
        int=(@watch.period||300).to_i
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
