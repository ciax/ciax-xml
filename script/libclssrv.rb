#!/usr/bin/ruby
require "libxmldoc"
require "libclscmd"
require "libclsstat"
require "libdev"
require "thread"
require "libauto"
require "libevent"

class ClsSrv

  def initialize(cls,id,iocmd,conv=nil)
    cdb=XmlDoc.new('cdb',cls)
    @cdbc=ClsCmd.new(cdb)
    @cdbs=ClsStat.new(cdb,id)
    @var={:cmd=>'upd',:int=>'10',:cls => cls,:issue =>''}
    @ddb=Dev.new(cdb['device'],id,iocmd)
    @cdbs.get_stat(@ddb.field)
    @conv=proc{|c| yield c}
    @q=Queue.new
    @errmsg=Array.new
    @auto=Auto.new(@conv,proc{|s| @q.push(s) if @q.empty? })
    @event=Event.new(cdb)
    device_thread
    sleep 0.01
    event_thread unless @event.empty?
    sleep 0.01
  end

  def prompt
    prom = @auto.auto.alive? ? '&' : ''
    prom << @var[:cls]
    prom << @var[:issue]
    prom << (@event.any?{|bg| bg[:act] } ? '!' : '')
    prom << ">"
  end

  def stat
    @cdbs.stat
  end

  def dispatch(stm)
    return @errmsg.shift unless @errmsg.empty?
    return if stm.empty?
    return "Blocking" if @event.blocking?(stm)
    @cdbc.session(@conv.call(stm)) {|cmd| @q.push(cmd)}
    "Accepted"
  rescue SelectID
    @auto.auto_upd(stm){|i,o| @cdbc.session(i,&o) }
  end

  private
  def device_thread
    Thread.new {
      loop {
        stm=@q.shift
        @var[:issue]='*'
        begin
          @ddb.devcom(stm)
          @cdbs.get_stat(@ddb.field)
        rescue
          @errmsg << $!.to_s
        ensure
          @var[:issue]=''
        end
      }
    }
  end

  def event_thread
    Thread.new{ 
      loop{ 
        @event.update{|k| @cdbs.stat(k)}
        @event.cmd('execution').each{|cmd|
          @cdbc.session(cmd.split(" ")){|c| @q.push(c)}
        } if @q.empty?
        sleep @event.interval
      }
    }
  end
end
