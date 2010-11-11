#!/usr/bin/ruby
require "libxmldoc"
require "libclscmd"
require "libclsstat"
require "libdev"
require "thread"
require "libclsevent"

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
    @buf=[]
    @cmd=ClsCmd.new(cdb)
    @stat=ClsStat.new(cdb,id)
    @event=ClsEvent.new(cdb).thread(@q){|k| @stat.stat(k)}
    @main=session_thread(cdb['device'],id,iocmd)
    sleep 0.01
  end

  def prompt
    prom = (@event.alive? ? "&" : "")
    prom << @cls
    prom << @issue
    prom << (@sleep ? '#' : '')
    prom << (@event.active? ? '!' : '')
    prom << ">"
  end

  def stat
    @stat.stat
  end

  def dispatch(stm)
    raise unless $errmsg.empty?
    return if stm.empty?
    return "Blocking" if @event.blocking?(stm)
    stm=yield stm
    @cmd.setcmd(stm)
    @buf.push(stm)
    flush_buf
    return "Accepted"
  rescue SelectID
    case stm[0]
    when 'sleep'
      @sleep=1
      @st=Thread.new(stm[1].to_i){|s|
        sleep s
        @sleep=nil
        flush_buf
      }
    else
      $errmsg << " sleep     : sleep [sec]"
      raise $errmsg.slice!(0..-1)
    end
    $errmsg.clear
  end
  
  def interrupt
    @q.clear
    @buf.clear
    @issue=''
    @event.interrupt.each{|c| @q.push(c)}
    @st.run if @st
    "Interrupt"
  end
  
  private
  def flush_buf
    return if @sleep
    while c=@buf.pop
      @q.push(c)
    end
  end

  def session_thread(dev,id,iocmd)
    Thread.new{
      ddb=Dev.new(dev,id,iocmd)
      @stat.get_stat(ddb.field)
      loop{
        begin
          @issue=''
          stm=@q.pop
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
