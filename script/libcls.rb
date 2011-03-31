#!/usr/bin/ruby
require "libstat"
require "libfrm"
require "libclscmd"
require "libclsstat"
require "libcmdbuf"
require "libwatch"
require "thread"

class Cls

  def initialize(doc,id,iocmd)
    raise "Init Param must be XmlDoc" unless XmlDoc === doc
    @cls=doc['id']
    $errmsg=''
    @stat=Stat.new(id,'status')
    @cc=ClsCmd.new(doc)
    @cs=ClsStat.new(doc,@stat)
    @buf=CmdBuf.new
    @event=Watch.new(doc['watch'])
    @main=session_thread(doc['frame'],id,iocmd)
    @watch=watch_thread
    sleep 0.01
  end

  def prompt
    prom = (stat['wach'] == "1" ? "&" : "")
    prom << (stat['evet'] == "1" ? '@' : '')
    prom << @cls
    prom << (stat['isu'] == "1" ? '*' : '')
    prom << (stat['wait'] == "1" ? '#' : '')
    prom << ">"
  end

  def stat
    stat={}
    stat['wach']=(@watch.alive? ? "1" : "0")
    stat['evet']=(@event.active? ? '1' : '0')
    stat['isu']=(@buf.issue? ? '1' : '0')
    stat['wait']=(@buf.wait? ? '1' : '0')
    stat.update(Hash[@stat])
  end

  def err?
    raise $errmsg.slice!(0..-1) unless $errmsg.empty?
  end

  def quit
    @stat.save
  end

  def dispatch(ssn)
    return nil if ssn.empty?
    raise "Blocking" if @event.blocking?(ssn)
    ssn=yield ssn
    @buf.send(1){@cc.setcmd(ssn).statements}
  rescue SelectID
    case ssn.shift
    when 'sleep'
      @buf.wait_for(ssn[0].to_i){}
    when 'waitfor'
      @buf.wait_for(10){ @stat.get(ssn[0]) == ssn[1] }
    else
      $errmsg << "== Internal Command ==\n"
      $errmsg << " sleep     : sleep [sec]\n"
      $errmsg << " waitfor   : [key] [val] (timeout=10)\n"
      raise SelectID,$errmsg.slice!(0..-1)
    end
  ensure
    $errmsg.clear
  end
  
  def interrupt
    @buf.interrupt(@event.interrupt)
    raise "Interrupt #{@event.interrupt}"
  end
  
  private
  def session_thread(dev,id,iocmd)
    Thread.new{
      fdb=Frm.new(XmlDoc.new('fdb',dev),id,iocmd)
      @cs.get_stat(fdb.field)
      loop{
        begin
          fdb.transaction(@buf.recv)
          @cs.get_stat(fdb.field)
        rescue
          $errmsg << $!.to_s
        end
      }
    }
  end

  def watch_thread
    Thread.new{
      while(@event.interval)
        @event.update{|key|
          @stat.get(key)
        }
        @buf.send{@event.issue}
        sleep @event.interval
      end
    }
  end
end
