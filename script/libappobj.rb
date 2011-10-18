#!/usr/bin/ruby
require "libmsg"
require "libbuffer"
require "libappcmd"
require "libwview"
require "libprint"
require "libwatch"
require "libsql"
require "thread"

class AppObj
  attr_reader :prompt,:view,:message
  def initialize(adb,frmobj)
    @v=Msg::Ver.new("appobj",9)
    Msg.type?(adb,AppDb)
    @prompt=''
    @id=adb['id']
    @fobj=frmobj
    @par=Param.new(adb[:command])
    @ac=AppCmd.new(@par)
    @view=Wview.new(@id,adb,@fobj.field)
    Thread.abort_on_exception=true
    @buf=Buffer.new
    @interval=(adb['interval']||1).to_i
    @event=Watch.new(adb,@view)
    @watch=watch_thread unless @event[:stat].empty?
    @main=command_thread
    @cl=Msg::List.new("== Internal Command ==")
    @cl.add('sleep'=>"sleep [sec]")
    @cl.add('waitfor'=>"[key=val] (timeout=10)")
    upd_prompt
  end

  def upd(cmd)
    case cmd.first
    when nil
      @message=nil
    when 'interrupt'
      stop=@event.interrupt
      @buf.interrupt{stop}
      @message="Interrupt #{stop}"
    when 'sleep'
      @buf.wait_for(cmd[1].to_i){}
      @message="Sleeping"
    when 'waitfor'
      k,v=cmd[1].split('=')
      @buf.wait_for(10){ @view['stat'][k] == v }
      @message="Waiting"
    else
      if @event.block_pattern === cmd.join(' ')
        @message="Blocking(#{@event.block_pattern.inspect})"
      else
        @buf.send{@par.set(cmd);@ac.getcmd}
        @message="ISSUED"
      end
    end
    upd_prompt
    self
  rescue SelectCMD
    raise SelectCMD,@cl.to_s
  end

  def to_s
    [@message,@prompt].compact.join("\n")
  end

  private
  def upd_prompt
    @prompt.replace(@id)
    @prompt << '@' if @watch && @watch.alive?
    @prompt << '&' if @event.active?
    @prompt << '*' if @buf.issue
    @prompt << '#' if @buf.wait
    @prompt << (@main.alive? ? '>' : 'X')
    self
  end

  def command_thread
    Thread.new{
      Thread.pass
      loop{
        begin
          @fobj.upd(@buf.recv)
          @v.msg{"Field Updated(#{@fobj.field['time']})"}
          @view.upd.save
          @v.msg{"Status Updated(#{@view['stat']['time']})"}
        rescue UserError
          Msg.alert(" in Command Thread")
          @buf.clear
        end
      }
    }
  end

  def watch_thread
    Thread.new{
      Thread.pass
      loop{
        begin
          @buf.auto{
            @event.upd.issue.map{|cmd|
              @par.set(cmd)
              @ac.getcmd
            }.flatten(1)
          }
        rescue SelectID
          Msg.warn($!)
        end
        sleep @interval
      }
    }
  end
end
