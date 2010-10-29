#!/usr/bin/ruby
require "libxmldoc"
require "libclscmd"
require "libclsstat"
require "libdevbg"
require "thread"
require "libauto"
require "libevent"

class ClsSrv

  def initialize(cls,id,iocmd,conv=nil)
    cdb=XmlDoc.new('cdb',cls)
    @cdbc=ClsCmd.new(cdb)
    @cdbs=ClsStat.new(cdb,id)
    @var={:cmd=>'upd',:int=>'10',:cls => cls}
    @ddb=DevBg.new(cdb['device'],id,iocmd){|s| @cdbs.get_stat(s) }
    @errmsg=@ddb.errmsg
    @cdbs.get_stat(@ddb.field)
    @conv=proc{|c| yield c}
    @auto=Auto.new(@conv,proc{|s| @ddb.push(s) if @ddb.empty? })
    @event=Event.new(cdb)
    event_thread unless @event.empty?
    sleep 0.01
  end

  def prompt
    prom = @auto.auto.alive? ? '&' : ''
    prom << @var[:cls]
    prom << @ddb.issue
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
    @cdbc.session(@conv.call(stm)) {|cmd| @ddb.push(cmd)}
    "Accepted"
  rescue SelectID
    @auto.auto_upd(stm){|i,o| @cdbc.session(i,&o) }
  end

  private

  def event_thread
    Thread.new{
      loop{
        @event.update{|k| @cdbs.stat(k)}
        @event.cmd('execution').each{|cmd|
          @cdbc.session(cmd.split(" ")){|c| @ddb.push(c)}
        } if @ddb.empty?
        sleep @event.interval
      }
    }
  end
end
