#!/usr/bin/ruby
require "libverbose"
require "libiostat"
require "libbuffer"
require "libappcmd"
require "libappstat"
require "libwatch"
require "thread"

class AppObj
  attr_reader :prompt
  def initialize(adb,stat)
    @prompt=[adb['id']]
    @v=Verbose.new("ctl",6)
    @stat=stat
    @ac=AppCmd.new(adb)
    @as=AppStat.new(adb,@stat)
    Thread.abort_on_exception=true
    @buf=Buffer.new
    @interval=(adb['interval']||1).to_i
    @event=Watch.new(adb,@stat)
    @watch=watch_thread
    @main=cmdset_thread{|buf| yield buf}
    @v.add("== Internal Command ==")
    @v.add('sleep'=>"sleep [sec]")
    @v.add('waitfor'=>"[key] [val] (timeout=10)")
    upd
  end

  def dispatch(line)
    upd
    return interrupt unless line
    return if /^(stat|)$/ === line
    return "Blocking" if @event.blocking?(line)
    line=yield line if defined? yield
    ssn=line.split(' ')
    case ssn[0]
    when 'sleep'
      @buf.wait_for(ssn[0].to_i){}
    when 'waitfor'
      @buf.wait_for(10){ @stat.get(ssn[0]) == ssn[1] }
    else
      @buf.send{@ac.setcmd(ssn).cmdset}
    end
    upd
    "ISSUED"
  rescue SelectID
    @v.list
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
    "Interrupt #{stop}"
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
          @as.upd(yield @buf.recv)
          @stat.save
        }
      rescue UserError
        @v.alert(" in Command Thread")
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
