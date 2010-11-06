#!/usr/bin/ruby
require "libxmldoc"
require "libclscmd"
require "libclsstat"
require "libdev"
require "thread"
require "libclsauto"
require "libclsevent"

class ClsSrv

  def initialize(cls,id,iocmd)
    cdb=XmlDoc.new('cdb',cls)
  rescue RuntimeError
    abort $!.to_s
  else
    @cls=cls
    @issue=''
    @errmsg=[]
    @q=Queue.new
    @cmd=ClsCmd.new(cdb)
    @stat=ClsStat.new(cdb,id)
    @auto=ClsAuto.new(@q)
    @event=ClsEvent.new(cdb,@errmsg).thread(@q){|k| @stat.stat(k)}
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
    return @errmsg.shift unless @errmsg.empty?
    return if stm.empty?
    return "Blocking" if @event.blocking?(stm)
    @cmd.session(yield(stm))
    @q.push(yield(stm))
    "Accepted"
  rescue SelectID
    @auto.auto_upd(stm){|s| @cmd.session(yield(s)) }
  end

  private
  def session_thread(dev,id,iocmd)
    Thread.new{
      ddb=Dev.new(dev,id,iocmd)
      begin
        loop{
          begin
            @stat.get_stat(ddb.field)
            @issue=''
            stm=@q.pop
            @issue='*'
            @cmd.session(stm).each{|c|
              ddb.devcom(c)
            }
          rescue
            @errmsg << $!.to_s
          end
        }
      rescue Interrupt
        @q.clear
        @event.interrupt.each{|c| ddb.devcom(c)}
        @errmsg << "STOP"
      end
    }
  end
end
