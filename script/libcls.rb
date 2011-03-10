#!/usr/bin/ruby
require "libfrm"
require "libclscmd"
require "libclsstat"
require "libcmdbuf"
require "libclsevent"
require "thread"

class Cls

  def initialize(cdb,id,iocmd)
    @cls=cdb['id']
    $errmsg=''
    @cmd=ClsCmd.new(cdb)
    @stat=ClsStat.new(cdb,id)
    @buf=CmdBuf.new
    @event=ClsEvent.new(cdb['watch'])
    @main=session_thread(cdb['frame'],id,iocmd)
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
    stat.update(@stat.stat)
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
    ary=[]
    @event.interrupt.each{|cmd|
      @cmd.setcmd(cmd.split(' ')).session.each{|c|
        ary << c
      }
    }
    @buf.interrupt(ary)
    raise "Interrupt #{@event.interrupt}"
  end
  
  private
  def session_thread(dev,id,iocmd)
    Thread.new{
      fdb=Frm.new(dev,id,iocmd)
      @stat.get_stat(fdb.field)
      loop{
        begin
          fdb.transaction(@buf.recv.split(' '))
          @stat.get_stat(fdb.field)
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
          @stat.stat(key)
        }
        @event.issue.each{|cmd|
          @cmd.setcmd(cmd.split(' ')).session.each{|c|
            @buf.send(c)
          }
        } if @buf.empty?
        sleep @event.interval
      end
    }
  end
end
