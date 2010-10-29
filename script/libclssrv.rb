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
    @cls=cls
    @q=Queue.new
    @issue=''
    @errmsg=[]
    cdb=XmlDoc.new('cdb',cls)
    @cmd=ClsCmd.new(cdb)
    @stat=ClsStat.new(cdb,id)
    @ddb=Dev.new(cdb['device'],id,iocmd)
    @stat.get_stat(@ddb.field)
    @input=proc{|c| yield c}
    @output=proc{|s| @ddb.push(s) if @ddb.empty? }
    @auto=ClsAuto.new(@input,@output)
    @event=ClsEvent.new(cdb)
    session_thread
    event_thread unless @event.empty?
    sleep 0.01
  end

  def prompt
    prom = @auto.auto.alive? ? '&' : ''
    prom << @cls
    prom << @issue
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
    @cmd.session(@input.call(stm)){}
    @q.push(stm)
    "Accepted"
  rescue SelectID
    @auto.auto_upd(stm){|i,o| @cmd.session(i,&o) }
  end

  private
  def session_thread
    Thread.new{
      loop{
        stm=@q.pop
        @issue='*'
        begin
          @cmd.session(@input.call(stm)) {|c|
            @ddb.devcom(c)
            @stat.get_stat(@ddb.field)
          }
        rescue
          @errmsg << $!.to_s
        ensure
          @issue=''
        end
      }
    }
  end

  def event_thread
    Thread.new{
      loop{
        @event.update{|k| @stat.stat(k)}
        @event.cmd('execution').each{|cmd|
          @q.push(cmd.split(" "))
        } if @q.empty?
        sleep @event.interval
      }
    }
  end
end
