#!/usr/bin/ruby
require "libxmldoc"
require "libclscmd"
require "libclsstat"
require "libdev"
require "thread"
require "libauto"

class ClsSrv

  def initialize(cls,id,iocmd)
    cdb=XmlDoc.new('cdb',cls)
    @cdbc=ClsCmd.new(cdb)
    @cdbs=ClsStat.new(cdb,id)
    @var={:cmd=>'upd',:int=>'10',:cls => cls,:issue =>''}
    @ddb=Dev.new(cdb['device'],id,iocmd)
    @cdbs.get_stat(@ddb.field)
    @q=Queue.new
    @errmsg=Array.new
    @auto=Auto.new(@q,@cdbc)
    device_thread
    sleep 0.01
  end

  def prompt
    prom = @auto.auto.alive? ? '&' : ''
    prom << @var[:cls]
    prom << @var[:issue]
    prom << ">"
  end

  def stat
    @cdbs.stat
  end

  def dispatch(stm)
    return @errmsg.shift unless @errmsg.empty?
    return if stm.empty?
    @cdbc.session(yield stm) {|cmd| @q.push(cmd)}
    "Accepted"
  rescue SelectID
    @auto.auto_upd(stm){|s| yield s}
  rescue RuntimeError
    $!.to_s
  rescue
    $!.to_s+$@.to_s
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
end
