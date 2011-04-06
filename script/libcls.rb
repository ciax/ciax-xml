#!/usr/bin/ruby
require "libstat"
require "libclscmd"
require "libclsstat"
require "libcmdbuf"
require "libwatch"
require "thread"

class Cls

  def initialize(doc,id)
    raise "Init Param must be XmlDoc" unless XmlDoc === doc
    @cls=doc['id']
    $errmsg=''
    @stat=Stat.new(id,'status')
    @field=Stat.new(id,"field")
    @cc=ClsCmd.new(doc)
    @cs=ClsStat.new(doc,@stat,@field)
    @buf=CmdBuf.new
    @event=Watch.new(doc['watch'])
    @watch=watch_thread
    @main=Thread.new{
      begin
        loop{
          @field.update(yield @buf.recv)
          @cs.get_stat
        }
      rescue
        $errmsg << $!.to_s
      end
    }
    sleep 0.01
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
    Hash[@stat]
  end

  def quit
    @stat.save
  end

  def dispatch(ssn)
    raise $errmsg.slice!(0..-1) unless $errmsg.empty?
    return nil if ssn.empty?
    raise "Blocking" if @event.blocking?(ssn)
    case ssn[0]
    when 'sleep'
      @buf.wait_for(ssn[0].to_i){}
    when 'waitfor'
      @buf.wait_for(10){ @stat.get(ssn[0]) == ssn[1] }
    else
      @buf.send(1){@cc.setcmd(ssn).statements}
    end
    "OK"
  rescue SelectID
    err="#{$!}"
    err << "== Internal Command ==\n"
    err << " sleep     : sleep [sec]\n"
    err << " waitfor   : [key] [val] (timeout=10)\n"
    raise SelectID,err
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
  def watch_thread
    Thread.new{
      begin
        while(@event.interval)
          @event.update{|key|
            @stat.get(key)
          }
          @buf.send{@event.issue}
          sleep @event.interval
        end
      rescue
        $errmsg << $!.to_s
      end
    }
  end
end
