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
    @issue=''
    $errmsg=''
    @q=Queue.new
    @cmd=ClsCmd.new(cdb)
    @stat=ClsStat.new(cdb,id)
    @event=ClsEvent.new(cdb).thread(@q){|k| @stat.stat(k)}
    @buf=ClsBuf.new(@q)
    @main=session_thread(cdb['device'],id,iocmd)
    sleep 0.01
  end

  def prompt
    prom = (@event.alive? ? "&" : "")
    prom << @cls
    prom << @issue
    prom << (@buf.wait? ? '#' : '')
    prom << (@event.active? ? '!' : '')
    prom << ">"
  end

  def stat
    @stat.stat
  end

  def dispatch(stm)
    raise $errmsg.slice!(0..-1) unless $errmsg.empty?
    return if stm.empty?
    return "Blocking" if @event.blocking?(stm)
    stm=yield stm
    @cmd.setcmd(stm)
    @buf.issue(stm)
  rescue SelectID
    case stm[0]
    when 'sleep'
      @buf.wait{ sleep stm[1].to_i }
    else
      $errmsg << " sleep     : sleep [sec]"
      raise $errmsg.slice!(0..-1)
    end
  ensure
    $errmsg.clear
  end
  
  def interrupt
    @issue=''
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
          @issue=''
          stm=@q.shift
          @issue='*'
          @cmd.setcmd(stm).session.each{|c|
            break if @issue == ''
            ddb.transaction(c)
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
