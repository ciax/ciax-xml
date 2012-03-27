#!/usr/bin/ruby
require "libappobj"
require "libmsg"
require "libcommand"
require "libappcmd"
require "libwview"
require "libbuffer"
require "thread"
require "libmodlog"
require "json"

class AppSv < AppObj
  def initialize(adb,fint)
    super(adb)
    @v=Msg::Ver.new(self,9)
    @id=adb['id']
    @fint=Msg.type?(fint,FrmObj)
    @cobj=AppCmd.new(adb[:command])
    stat=AppStat.new(adb,@fint.field).upd
    @view=Wview.new(adb,stat,@fint.field.key?('ver'))
    Thread.abort_on_exception=true
    @buf=Buffer.new.thread{|fcmd| @fint.exe(fcmd) }
    @buf.at_flush << proc{
      @view.upd.save
      sleep (@view['watch']['interval']||1).to_f/10
      sendfrm(@view['watch'].issue,2)
    }
    # Logging if version number exists
    extend(ModLog).startlog('appcmd',@id,@view['ver']) if @view.key?('ver')
    auto_update
    upd_prompt
  end

  #cmd is array
  def exe(cmd)
    msg=nil
    case cmd.first
    when nil
    when 'interrupt'
      int=@view['watch'].interrupt
      sendfrm(int,0)
      msg="Interrupt #{int}"
    when 'flush'
      @fint.field.load
      @buf.at_flush.upd
    when 'set'
      hash={}
      cmd[1..-1].each{|s|
        k,v=s.split('=')
        hash[k]=v
      }
      @view.set(hash).save
      msg="Set #{hash}"
    else
      if @view['watch'].block?(cmd)
        msg="Blocking(#{cmd})"
      else
        sendfrm([cmd])
        msg="ISSUED"
      end
    end
    upd_prompt
    msg
  end

  private
  def upd_prompt
    @prompt.replace(@id)
    @prompt << '@' if @tid && @tid.alive?
    @prompt << '&' if @view['watch'].active?
    @prompt << '*' if @buf.issue
    @prompt << (@buf.alive? ? '>' : 'X')
    self
  end

  # ary is bunch of appcmd array (ary of ary)
  def sendfrm(ary,pri=1)
    @buf.send(pri){
      # Making bunch of frmcmd array (ary of ary)
      ary.map{|cmd|
        @cobj.set(cmd)
        logging(cmd)
        @cobj.get
      }.flatten(1)
    }
  end

  def logging(cmd)
    append(JSON.dump(@view['watch']['active']),cmd) if is_a?(ModLog)
  end

  def auto_update
    @tid=Thread.new{
      Thread.pass
      int=(@view['watch'].period||300).to_i
      cmd=[['upd']]
      loop{
        begin
          sendfrm(cmd,2)
        rescue SelectID
          Msg.warn($!)
        end
        @v.msg{"Auto Update(#{@view['stat']['time']})"}
        sleep int
      }
    }
    self
  end
end
