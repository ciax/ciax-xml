#!/usr/bin/ruby
require "libmsg"
require "libbuffer"
require "libfrmobj"
require "libappcmd"
require "libwview"
require "libwatch"
require "libsql"
require "thread"

class AppObj
  attr_reader :prompt,:view
  def initialize(adb,io)
    @v=Msg::Ver.new("appobj",9)
    Msg.type?(adb,AppDb)
    id=adb['id']
    @prompt=[id]
    @fobj=FrmObj.new(adb.cover_frm,id,io)
    @ac=AppCmd.new(adb)
    @view=Wview.new(id,adb,@fobj.field)
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
    res=nil
    case line
    when /^(stat|)$/
    when /^interrupt$/
      stop=@event.interrupt
      @buf.interrupt{stop}
      res="Interrupt #{stop}\n"
    when @event.block_pattern
      res="Blocking(#{@event.block_pattern.inspect})\n"
    when /^sleep */
      @buf.wait_for($'.to_i){}
      res="Sleeping\n"
    when /^waitfor */
      k,v=$'.split('=')
      @buf.wait_for(10){ @view['stat'][k] == v }
      res="Waiting\n"
    else
      @buf.send{@ac.setcmd(line.split(' '))}
      res="ISSUED\n"
    end
    upd_prompt
    res
  rescue SelectCMD
    raise SelectCMD,@cl.to_s
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
