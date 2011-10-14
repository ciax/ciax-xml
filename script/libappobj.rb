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
  attr_reader :prompt,:view,:to_s
  def initialize(adb,frmobj)
    @v=Msg::Ver.new("appobj",9)
    Msg.type?(adb,AppDb)
    id=adb['id']
    @fobj=frmobj
    @ac=AppCmd.new(adb)
    @view=Wview.new(id,adb,@fobj.field)
    @prompt=@view['prompt']=[id]
    @prt=Print.new(adb[:status],@view)
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

  def upd(line)
    case line
    when /^(stat|)$/
      @view['message']=nil
    when /^interrupt$/
      stop=@event.interrupt
      @buf.interrupt{stop}
      @view['message']="Interrupt #{stop}\n"
    when @event.block_pattern
      @view['message']="Blocking(#{@event.block_pattern.inspect})\n"
    when /^sleep */
      @buf.wait_for($'.to_i){}
      @view['message']="Sleeping\n"
    when /^waitfor */
      k,v=$'.split('=')
      @buf.wait_for(10){ @view['stat'][k] == v }
      @view['message']="Waiting\n"
    else
      @buf.send{@ac.setcmd(line.split(' '))}
      @view['message']="ISSUED\n"
    end
    upd_prompt
    self
  rescue SelectCMD
    raise SelectCMD,@cl.to_s
  end

  def to_s
    @view['message']||@prt
  end

  private
  def upd_prompt
    @prompt.slice!(1..-1)
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
              @ac.setcmd(cmd)
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
