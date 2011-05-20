#!/usr/bin/ruby
require "libverbose"
require "libiostat"
require "libbuffer"
require "libclscmd"
require "libclsstat"
require "libwatch"
require "thread"

class Cls
  def initialize(cdb,id)
    @cls=cdb['id'].freeze
    @v=Verbose.new("ctl",6)
    @field=IoStat.new(id,"field")
    @cc=ClsCmd.new(cdb)
    @cs=ClsStat.new(cdb,@field)
    @stat=IoStat.new(id,@cs.get_stat)
    Thread.abort_on_exception=true
    @buf=Buffer.new
    @event=Watch.new(cdb)
    @watch=watch_thread
    @main=session_thread{|buf| yield buf}
  end

  def prompt
    prom=@cls.dup
    if @stat['wach'] == "1"
      prom << (@stat['evet'] == "1" ? '@' : '&')
    end
    prom << (@stat['isu'] == "1" ? '*' : '')
    prom << (@stat['wait'] == "1" ? '#' : '')
    prom << (@main.alive? ? ">" : "X")
  end

  def stat
    @stat['wach']=(@watch.alive? ? "1" : "0")
    @stat['evet']=(@event.active? ? '1' : '0')
    @stat['isu']=(@buf.issue? ? '1' : '0')
    @stat['wait']=(@buf.wait? ? '1' : '0')
    @stat.to_h
  end

  def quit
    @stat.save
  end

  def dispatch(ssn)
    return nil if ssn.empty?
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
    list={}
    list['sleep']="sleep [sec]"
    list['waitfor']="[key] [val] (timeout=10)"
    @v.list(list,"== Internal Command ==")
  end

  def interrupt
    stop=@event.interrupt
    if stop.empty?
      raise ''
    else
      @buf.interrupt(stop)
      raise "Interrupt #{stop}"
    end
  end
  
  private
  def session_thread
    Thread.new{
      Thread.pass
      begin
        loop{
          @field.update(yield @buf.recv)
          @cs.get_stat
        }
      rescue SelectID
        raise "Session Thread Error\n"+$!.to_s
      end
    }
  end
  def watch_thread
    Thread.new{
      Thread.pass
      while(@event.interval)
        @event.update{|key|
          @stat[key]
        }
        @buf.auto{@event.issue}
        sleep @event.interval
      end
    }
  end
end
