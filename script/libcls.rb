#!/usr/bin/ruby
require "libxmldoc"
require "libclscmd"
require "libclsstat"
require "libcmdbuf"
require "libclsevent"
require "libdev"
require "thread"

class Cls

  def initialize(cls,id,iocmd)
    cdb=XmlDoc.new('cdb',cls)
  rescue SelectID
    abort $!.to_s
  else
    @cls=cls
    $errmsg=''
    @cmd=ClsCmd.new(cdb)
    @stat=ClsStat.new(cdb,id)
    @buf=CmdBuf.new
    @event=ClsEvent.new(cdb)
    @main=session_thread(cdb['device'],id,iocmd)
    @watch=watch_thread
    sleep 0.01
  end

  def prompt
    prom = (@watch.alive? ? "&" : "")
    prom << (@event.active? ? '@' : '')
    prom << @cls
    prom << (@buf.issue? ? '*' : '')
    prom << (@buf.wait? ? '#' : '')
    prom << ">"
  end

  def stat
    @stat.stat
  end

  def err?
    raise $errmsg.slice!(0..-1) unless $errmsg.empty?
  end

  def dispatch(stm)
    return nil if stm.empty?
    raise "Blocking" if @event.blocking?(stm)
    stm=yield stm
    @cmd.setcmd(stm).session.each{|c|
      @buf.send(c,1)
    }
  rescue SelectID
    case stm.shift
    when 'sleep'
      @buf.wait_for(stm[0].to_i){}
    when 'waitfor'
      @buf.wait_for(10){ @stat.stat(stm[0]) == stm[1] }
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
      ddb=Dev.new(dev,id,iocmd)
      @stat.get_stat(ddb.field)
      loop{
        begin
          ddb.transaction(@buf.recv.split(' '))
          @stat.get_stat(ddb.field)
        rescue RuntimeError
          $errmsg << $!.to_s
        end
      }
    }
  end

  def watch_thread
    Thread.new{
      exit unless @event.interval
      loop{
        @event.update{|key|
          @stat.stat(key)
        }
        @event.issue.each{|stm|
          #          @cmd.setcmd(stm).session.each{|c|
          @buf.send(stm)
          #          }
        } if @buf.empty?
        sleep @event.interval
      }
    }
  end
end
