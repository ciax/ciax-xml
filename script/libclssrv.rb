#!/usr/bin/ruby
require "libxmldoc"
require "libclscmd"
require "libclsstat"
require "libdev"
require "thread"
require "libauto"

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
    @cdbc.session(@conv.yield stm) {|cmd| @q.push(cmd)}
    "Accepted"
  rescue SelectID
    @auto.auto_upd(stm){|i,o| @cdbc.session(i,&o) }
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
