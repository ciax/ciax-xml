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
    @ac=AppCmd.new(adb[:command])
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
    cl=Msg::List.new("Internal Command",2)
    cl.add('view'=>"View Stat mode")
    cl.add('stat'=>"Raw Stat mode")
    cl.add('field'=>"Field Stat mode")
    cl.add('watch'=>"Watch mode")
    cl.add('set'=>"[key=val] ..")
    @ac.cl.push(cl)
    upd_prompt
  end

  def upd(cmd)
    @message=nil
    case cmd.first
    when nil
    when 'view'
      @output=@print
    when 'stat'
      @output=@view['stat']
    when 'watch'
      @output=@watch
    when 'field'
      @output=@fobj
    when 'interrupt'
      int=@watch.interrupt
      @buf.send(0){frmcmds(int)}
      @message="Interrupt #{int}"
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
  end

  def to_s
    @output.to_s
  end

  def commands
    @ac.cl.keys
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
      @ac.set(cmd).get
    }.flatten(1)
  end
end
