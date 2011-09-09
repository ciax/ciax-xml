#!/usr/bin/ruby
require "libmsg"
require "libbuffer"
require "libappcmd"
require "libappstat"
require "libwatch"
require "thread"

class AppObj
  attr_reader :prompt
  def initialize(adb,view)
    @view=view
    @stat=view['stat']
    @prompt=[adb['id']]
    @v=Msg::Ver.new("ctl",6)
    @ac=AppCmd.new(adb[:command])
    @as=AppStat.new(adb[:status])
    Thread.abort_on_exception=true
    @buf=Buffer.new
    @interval=(adb['interval']||1).to_i
    @event=Watch.new(adb,@stat)
    @watch=watch_thread
    @main=cmdset_thread{|buf| yield buf}
    @cl=Msg::List.new("== Internal Command ==")
    @cl.add('sleep'=>"sleep [sec]")
    @cl.add('waitfor'=>"[key] [val] (timeout=10)")
    upd
  end

  def dispatch(line)
    upd
    return interrupt unless line
    return yield if /^(stat|)$/ === line
    return "Blocking\n" if @event.blocking?(line)
    ssn=line.split(' ')
    case ssn[0]
    when 'sleep'
      @buf.wait_for(ssn[1].to_i){}
    when 'waitfor'
      @buf.wait_for(10){ @stat[ssn[1]] == ssn[2] }
    else
      @buf.send{@ac.setcmd(ssn).cmdset}
    end
    upd
    "ISSUED\n"
  rescue SelectID
    @cl.exit
  end

  def upd
    i=0
    upd_elem(@watch.alive?,'wach',i+=1,'@')
    upd_elem(@event.active?,'evet',i+=1,'&')
    upd_elem(@buf.issue?,'isu',i+=1,'*')
    upd_elem(@buf.wait?,'wait',i+=1,'#')
    upd_elem(@main.alive?,nil,i+=1,'>','X')
    self
  end

  def interrupt
    stop=@event.interrupt
    @buf.interrupt{stop} unless stop.empty?
    "Interrupt #{stop}\n"
  end

  private
  def upd_elem(flg,key,idx,sym=nil,sym2='')
    @stat[key]= flg ? '1' : '0' if key
    @prompt[idx]= flg ? sym : sym2 if idx
    flg
  end

  def cmdset_thread
    Thread.new{
      Thread.pass
      begin
        loop{
          @view.upd(@as.conv(yield @buf.recv)).save
        }
      rescue UserError
        Msg.alert(" in Command Thread")
      end
    }
  end

  def watch_thread
    Thread.new{
      Thread.pass
      until(@event.empty?)
        @event.update
        @buf.auto{@event.issue}
        sleep @interval
      end
    }
  end
end
