#!/usr/bin/ruby
require "libmsg"
require "libparam"
require "libappcmd"
require "libwview"
require "libprint"
require "libbuffer"
require "libwatch"
require "thread"

class AppObj
  attr_reader :prompt,:message
  def initialize(adb,frmobj)
    @v=Msg::Ver.new("appobj",9)
    Msg.type?(adb,AppDb)
    @prompt=''
    @id=adb['id']
    @fobj=frmobj
    @par=Param.new(adb[:command])
    @ac=AppCmd.new(@par)
    @view=Wview.new(@id,adb,@fobj.field)
    @output=@print=Print.new(adb,@view)
    Thread.abort_on_exception=true
    @buf=Buffer.new.thread{|cmd|
      @fobj.upd(cmd)
      @view.upd.save
      @v.msg{"Status Updated(#{@view['stat']['time']})"}
    }
    @watch=Watch.new(adb,@view).thread{|cmd|
      @buf.send(2){frmcmds(cmd)}
    }
    @cl=Msg::List.new("== Internal Command ==")
    @cl.add('set'=>"[key=val] ..")
    @cl.add('sleep'=>"sleep [sec]")
    @cl.add('waitfor'=>"[key=val] (timeout=10)")
    @cl.add('view'=>"View mode")
    @cl.add('raw'=>"Raw Stat mode")
    @cl.add('watch'=>"Watch mode")
    upd_prompt
  end

  def upd(cmd)
    @message=nil
    case cmd.first
    when nil
    when 'view'
      @output=@print
    when 'raw'
      @output=@view['stat']
    when 'watch'
      @output=@watch
    when 'interrupt'
      int=@watch.interrupt
      @buf.send(0){frmcmds(int)}
      @message="Interrupt #{int}"
    when 'sleep'
      @buf.wait_for(cmd[1].to_i){}
      @message="Sleeping"
    when 'waitfor'
      k,v=cmd[1].split('=')
      @buf.wait_for(10){ @view.stat(k) == v }
      @message="Waiting"
    when 'set'
      hash={}
      cmd[1..-1].each{|s|
        k,v=s.split('=')
        hash[k]=v
      }
      @view.set(hash).save
      @message="Set #{hash}"
    else
      if @watch.block?(cmd)
        @message="Blocking(#{cmd})"
      else
        @buf.send{frmcmds([cmd])}
        @message="ISSUED"
      end
    end
    upd_prompt
    self
  rescue SelectCMD
    @cl.error
  end

  def to_s
    @output.to_s
  end

  def commands
    @par.commands+@cl.keys
  end

  private
  def upd_prompt
    @prompt.replace(@id)
    @prompt << '@' if @watch.alive?
    @prompt << '&' if @watch.active?
    @prompt << '*' if @buf.issue
    @prompt << '#' if @buf.wait
    @prompt << (@buf.alive? ? '>' : 'X')
    self
  end

  def frmcmds(ary)
    ary.map{|cmd|
      @par.set(cmd)
      @ac.getcmd
    }.flatten(1)
  end
end
