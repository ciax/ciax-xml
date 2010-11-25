#!/usr/bin/ruby
require "libxmldoc"
require "libclscmd"
require "libclsstat"
require "libclsbuf"
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
    @q=Queue.new
    @cmd=ClsCmd.new(cdb)
    @stat=ClsStat.new(cdb,id)
    @buf=ClsBuf.new(@q)
    @event=ClsEvent.new(cdb,@buf){|k| @stat.stat(k)}
    @main=session_thread(cdb['device'],id,iocmd)
    sleep 0.01
  end

  def prompt
    prom = (@event.alive? ? "&" : "")
    prom << @cls
    prom << (@buf.issue? ? '*' : '')
    prom << (@buf.wait? ? '#' : '')
    prom << (@event.active? ? '@' : '')
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
    return "Blocking" if @event.blocking?(stm)
    stm=yield stm
    @cmd.setcmd(stm)
    @buf.push(stm)
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
    "Interrupt"
  end
  
  private
  def session_thread(dev,id,iocmd)
    Thread.new{
      ddb=Dev.new(dev,id,iocmd)
      @stat.get_stat(ddb.field)
      loop{
        begin
          stm=@buf.recv
          @cmd.setcmd(stm).session.each{|c|
            break unless @buf.issue?
            ddb.transaction(c.split(' '))
            @stat.get_stat(ddb.field)
          }
        rescue RuntimeError
          $errmsg << $!.to_s
        rescue
          $errmsg << $!.to_s+$@.to_s
        end
      }
    }
  end
end
