#!/usr/bin/ruby
require "libxmldoc"
require "libclscmd"
require "libclsstat"
require "libdev"
require "thread"
require "libclsauto"
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
    @cmd=ClsCmd.new(cdb)
    @stat=ClsStat.new(cdb,id)
    @auto=ClsAuto.new(@q)
    @event=ClsEvent.new(cdb).thread(@q){|k| @stat.stat(k)}
    session_thread(cdb['device'],id,iocmd)
    sleep 0.01
  end

  def prompt
    prom = @auto.active ? "&" : ''
    prom << @cls
    prom << @issue
    prom << (@event.active? ? '!' : '')
    prom << (@event.alive? ? ">" : "<")
  end

  def stat
    @stat.stat
  end

  def dispatch(stm)
    if $errmsg.empty?
      return if stm.empty?
      return "Blocking" if @event.blocking?(stm)
      begin
        @cmd.setcmd(yield(stm))
        @q.push(yield(stm))
        return "Accepted"
      rescue SelectID
        begin
          return @auto.auto_upd(stm){|s|
            @cmd.setcmd(yield(s)).session
          }
        rescue SelectID
        end
      end
    end
    raise $errmsg.slice!(0..-1)
  end
  
  def interrupt
    @q.clear
    @issue=''
    @event.interrupt.each{|c| @q.push(c)}
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
          stm=@q.pop
          @issue='*'
          @cmd.setcmd(stm).session.each{|c|
            break if @issue == ''
            ddb.devcom(c)
            @stat.get_stat(ddb.field)
          }
        rescue
          $errmsg << $!.to_s+$@.to_s+stm
        end
      }
    }
  end
end
