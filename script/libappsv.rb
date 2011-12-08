#!/usr/bin/ruby
require "libapp"
require "libmsg"
require "libcommand"
require "libappcmd"
require "libwview"
require "libbuffer"
require "libwatch"
require "thread"

class AppSv < App
  def initialize(adb,fint)
    super(adb)
    @v=Msg::Ver.new("appobj",9)
    @id=adb['id']
    @fint=Msg.type?(fint,Frm)
    @cobj=AppCmd.new(adb[:command])
    @view=Wview.new(adb,@fint.field)
    Thread.abort_on_exception=true
    @buf=Buffer.new.thread{|cmd|
      @fint.exe(cmd)
      @view.upd.save
      @v.msg{"Status Updated(#{@view['stat']['time']})"}
    }
    @watch=Watch.new(adb,@view).thread{|cmd|
      @buf.send(2){frmcmds(cmd)}
    }.extend(WatchPrt)
    @watch.extend(WatchLog).startlog(@id,@view['ver']) if @view.key?('ver')
    cl=Msg::List.new("Internal Command",2)
    cl.add('set'=>"[key=val] ..")
    cl.add('flush'=>"Flush Status")
    @cobj.list.push(cl)
    upd_prompt
  end

  def exe(cmd)
    msg=nil
    case cmd.first
    when nil
    when 'interrupt'
      int=@watch.interrupt
      @buf.send(0){frmcmds(int)}
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
        @buf.send{frmcmds([cmd])}
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

  def frmcmds(ary)
    ary.map{|cmd|
      @cobj.set(cmd).get
    }.flatten(1)
  end
end
