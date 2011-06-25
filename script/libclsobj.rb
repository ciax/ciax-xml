#!/usr/bin/ruby
require "libverbose"
require "libiostat"
require "libbuffer"
require "libclscmd"
require "libclsstat"
require "libwatch"
require "thread"

class ClsObj
  attr_reader :stat,:prompt
  def initialize(cdb,id)
    @prompt=[cdb['id']]
    @v=Verbose.new("ctl",6)
    @field=IoStat.new(id,"field")
    @cc=ClsCmd.new(cdb)
    @cs=ClsStat.new(cdb,@field)
    @stat=@cs.stat
    Thread.abort_on_exception=true
    @buf=Buffer.new
    @interval=cdb['interval']||1
    @event=Watch.new(cdb,@stat)
    @watch=watch_thread
    @main=session_thread{|buf| yield buf}
    @v.add("== Internal Command ==")
    @v.add('sleep'=>"sleep [sec]")
    @v.add('waitfor'=>"[key] [val] (timeout=10)")
    upd
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

  def dispatch(ssn)
    return false if ssn.empty?
    raise "Blocking" if @event.blocking?(ssn)
    case ssn[0]
    when 'sleep'
      @buf.wait_for(ssn[0].to_i){}
    when 'waitfor'
      @buf.wait_for(10){ @stat.get(ssn[0]) == ssn[1] }
    else
      @buf.send{@cc.setcmd(ssn).statements}
    end
    "ISSUED"
  rescue SelectID
    @v.list
  end

  def interrupt
    stop=@event.interrupt
    unless stop.empty?
      @buf.interrupt(stop)
      "Interrupt #{stop}"
    end
  end

  private
  def upd_elem(flg,key,idx,sym=nil,sym2='')
    @stat[key]= flg ? '1' : '0' if key
    @prompt[idx]= flg ? sym : sym2 if idx
    flg
  end

  def session_thread
    Thread.new{
      Thread.pass
      begin
        loop{
          @field.update(yield @buf.recv)
          @cs.upd
        }
      rescue SelectID
        raise "Session Thread Error\n"+$!.to_s
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
