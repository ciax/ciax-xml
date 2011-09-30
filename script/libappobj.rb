#!/usr/bin/ruby
require "libmsg"
require "libbuffer"
require "libfrmobj"
require "libappcmd"
require "libappstat"
require "libwatch"
require "libsql"
require "thread"


class AppObj < String
  attr_reader :prompt
  def initialize(adb,view,field,io)
    @v=Msg::Ver.new("appobj",9)
    @view=view
    stat=view['stat']
    @prompt=[adb['id']]
    @fobj=FrmObj.new(adb,field,io)
    @ac=AppCmd.new(adb[:command])
    @as=AppStat.new(adb[:status],field,stat)
    @sql=Sql.new(stat,view['id'])
    Thread.abort_on_exception=true
    @buf=Buffer.new
    @interval=(adb['interval']||1).to_i
    @event=Watch.new(adb,stat)
    @watch=watch_thread unless @event[:stat].empty?
    @main=command_thread
    @cl=Msg::List.new("== Internal Command ==")
    @cl.add('sleep'=>"sleep [sec]")
    @cl.add('waitfor'=>"[key=val] (timeout=10)")
    upd
  end

  def dispatch(line)
    case line
    when nil
      stop=@event.interrupt
      @buf.interrupt{stop}
      replace "Interrupt #{stop}\n"
    when /^(stat|)$/
      replace yield.to_s
    when @event.block_pattern
      replace "Blocking(#{@event.block_pattern.inspect})\n"
    when /^sleep */
      @buf.wait_for($'.to_i){}
      replace "Sleeping\n"
    when /^waitfor */
      k,v=$'.split('=')
      @buf.wait_for(10){ @view['stat'][k] == v }
      replace "Waiting\n"
    else
      @buf.send{@ac.setcmd(line.split(' '))}
      replace "ISSUED\n"
    end
    upd
    self
  rescue SelectCMD
    raise SelectCMD,@cl.to_s
  end

  def upd
    @prompt.slice!(1..-1)
    @prompt << '@' if @watch && @watch.alive?
    @prompt << '&' if @event.active?
    @prompt << '*' if @buf.issue
    @prompt << '#' if @buf.wait
    @prompt << (@main.alive? ? '>' : 'X')
    self
  end

  private
  def command_thread
    Thread.new{
      Thread.pass
      loop{
        begin
          @fobj.request(@buf.recv)
          @as.upd
          @view.upd.save
          @sql.upd.flush
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
