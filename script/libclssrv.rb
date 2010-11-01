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
    session_thread
    @auto=ClsAuto.new(@q)
    @event=[]
    cdb['events'].each_element{|e|
      @event << ClsEvent.new(e)
      @event.last.thread(@q)
      sleep 0.01
    } if cdb['events']
  end

  def prompt
    prom = @auto.active ? "&" : ''
    prom << @cls
    prom << @issue
    prom << (@event.any?{|e| e.active?} ? '!' : '')
    prom << ">"
  end

  def stat
    @stat.stat
  end

  def dispatch(stm)
    return @errmsg.shift unless @errmsg.empty?
    return if stm.empty?
    return "Blocking" if @event.any?{|e| e.blocking?(stm)}
    @cmd.session(yield(stm)){}
    @q.push(yield(stm))
    "Accepted"
  rescue SelectID
    @auto.auto_upd(stm){|s| @cmd.session(yield(s)) }
  end

  private
  def session_thread
    Thread.new{
      loop{
        stm=@q.pop
        @issue='*'
        begin
          @cmd.session(stm) {|c|
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
end
