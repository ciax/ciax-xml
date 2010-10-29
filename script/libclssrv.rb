#!/usr/bin/ruby
require "libxmldoc"
require "libclscmd"
require "libclsstat"
require "libdevbg"
require "thread"
require "libauto"
require "libevent"

class ClsSrv

  def initialize(cls,id,iocmd)
    @cls=cls
    cdb=XmlDoc.new('cdb',cls)
    @cmd=ClsCmd.new(cdb)
    @stat=ClsStat.new(cdb,id)
    @ddb=DevBg.new(cdb['device'],id,iocmd){|s| @stat.get_stat(s) }
    @errmsg=@ddb.errmsg
    @stat.get_stat(@ddb.field)
    @input=proc{|c| yield c}
    @output=proc{|s| @ddb.push(s) if @ddb.empty? }
    @auto=Auto.new(@input,@output)
    @event=Event.new(cdb)
    event_thread unless @event.empty?
    sleep 0.01
  end

  def prompt
    prom = @auto.auto.alive? ? '&' : ''
    prom << @cls
    prom << @ddb.issue
    prom << (@event.active? ? '!' : '')
    prom << ">"
  end

  def stat
    @stat.stat
  end

  def dispatch(stm)
    return @errmsg.shift unless @errmsg.empty?
    return if stm.empty?
    return "Blocking" if @event.blocking?(stm)
    @cmd.session(@input.call(stm)) {|c| @ddb.push(c)}
    "Accepted"
  rescue SelectID
    @auto.auto_upd(stm){|i,o| @cmd.session(i,&o) }
  end

  private

  def event_thread
    Thread.new{
      loop{
        @event.update{|k| @stat.stat(k)}
        @event.cmd('execution').each{|cmd|
          @cmd.session(cmd.split(" ")){|c| @ddb.push(c)}
        } if @ddb.empty?
        sleep @event.interval
      }
    }
  end
end
