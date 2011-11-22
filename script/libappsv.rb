#!/usr/bin/ruby
require "libappint"
require "libmsg"
require "libparam"
require "libappcmd"
require "libwview"
require "libprint"
require "libbuffer"
require "libwatch"
require "thread"

class AppSv < AppInt
  def initialize(adb,fint)
    super(adb)
    @v=Msg::Ver.new("appobj",9)
    @id=adb['id']
    @fint=Msg.type?(fint,FrmInt)
    @par=AppCmd.new(adb[:command])
    @view=Wview.new(adb,@fint.field)
    @output=@print=Print.new(adb,@view)
    Thread.abort_on_exception=true
    @buf=Buffer.new.thread{|cmd|
      @fint.exe(cmd)
      @view.upd.save
      @v.msg{"Status Updated(#{@view['stat']['time']})"}
    }
    @watch=Watch.new(adb,@view).thread{|cmd|
      @buf.send(2){frmcmds(cmd)}
    }
    cl=Msg::List.new("Internal Command",2)
    cl.add('print'=>"Print mode")
    cl.add('stat'=>"Stat mode")
    cl.add('field'=>"Field Stat mode")
    cl.add('watch'=>"Watch mode")
    cl.add('set'=>"[key=val] ..")
    @par.list.push(cl)
    upd_prompt
  end

  def exe(cmd)
    msg=nil
    case cmd.first
    when nil
    when 'print'
      @output=@print
    when 'stat'
      @output=@view['stat']
    when 'watch'
      @output=@watch
    when 'field'
      @output=@fint
    when 'interrupt'
      int=@watch.interrupt
      @buf.send(0){frmcmds(int)}
      msg="Interrupt #{int}"
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
    self
    msg
  end

  def to_s
    @output.to_s
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
      @par.set(cmd).get
    }.flatten(1)
  end
end
