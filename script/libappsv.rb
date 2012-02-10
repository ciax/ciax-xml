#!/usr/bin/ruby
require "libappobj"
require "libmsg"
require "libcommand"
require "libappcmd"
require "libwview"
require "libbuffer"
require "libwatch"
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
    @view=Wview.new(adb,@fint.field)
    @fint.field.updlist << proc{ @view.upd.save}
    Thread.abort_on_exception=true
    @buf=Buffer.new.thread{|cmd|
      @fint.exe(cmd)
      @v.msg{"Status Updated(#{@view['stat']['time']})"}
    }
    @watch=Watch.new(adb,@view).thread{|cmd|
      sendfrm(cmd,2)
    }.extend(WatchPrt)
    # Logging if version number exists
    extend(ModLog).startlog('appcmd',@id,@view['ver']) if @view.key?('ver')
    upd_prompt
  end

  def exe(cmd)
    msg=nil
    case cmd.first
    when nil
    when 'interrupt'
      int=@watch.interrupt
      sendfrm(int,0)
      msg="Interrupt #{int}"
    when 'flush'
      @fint.field.load
      @view.upd.save
    when 'set'
      hash={}
      cmd[1..-1].each{|s|
        k,v=s.split('=')
        hash[k]=v
      }
      @view.set(hash).save
      msg="Set #{hash}"
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

  private
  def upd_prompt
    @prompt.replace(@id)
    @prompt << '@' if @watch.alive?
    @prompt << '&' if @watch.active?
    @prompt << '*' if @buf.issue
    @prompt << (@buf.alive? ? '>' : 'X')
    self
  end

  def sendfrm(ary,pri=1)
    @buf.send(pri){
      ary.map{|cmd|
        @cobj.set(cmd)
        # Logging if version number exists
        if @view.key?('ver')
          str= pri > 1 ? JSON.dump(@watch[:active]) : nil
          append(str,cmd)
        end
        @cobj.get
      }.flatten(1)
    }
  end
end
