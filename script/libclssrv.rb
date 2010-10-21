#!/usr/bin/ruby
require "libxmldoc"
require "libclscmd"
require "libclsstat"
require "libdev"
require "thread"

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
    @auto=Thread.new{}
    device_thread
    sleep 0.01
  end

  def prompt
    prom = @auto.alive? ? '&' : ''
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
    begin
      @cdbc.session(yield stm) {|cmd| @q.push(cmd)}
      "Accepted"
    rescue SelectID
      case stm.shift
      when 'auto'
        auto_upd(stm.first)
      else
        msg=[$!.to_s]
        msg << "== Internal Command =="
        msg << " auto ?    : Auto Update (opt)"
        msg.join("\n")
      end
    end
  rescue RuntimeError
    $!.to_s
  rescue
    $!.to_s+$@.to_s
  end

  private
  def auto_upd(par)
    case par
    when 'stat'
      str=["Running(cmd=[#{@var[:cmd]}] int=[#{@var[:int]}])"]
      str.unshift("Not") unless @auto.alive?
      str.join(' ')
    when 'start'
      @auto.kill if @auto
      @auto=auto_thread
    when 'stop'
      if @auto
        @auto.kill
        sleep 0.1
      end
    when /^int=/
      num=$'
      if num.to_i > 0
        @var[:int]=num
      else
        raise "Out of Range"
      end
    when /^cmd=/
      line=$'
      begin
        setcmd(line){}
        @var[:cmd]=line
      rescue SelectID
        msg=["Invalid Command"]
        msg << $!.to_s
      end
    else
      msg=["Usage: auto [opt]"]
      msg << " stat       : Auto update Status"
      msg << " start      : Start Auto update"
      msg << " stop       : Stop Auto update"
      msg << " cmd=       : Set Commands (cmd:par;..)"
      msg << " int=       : Set Interval (sec)"
      msg.join("\n")
    end
  end

  def setcmd(line)
    line.split(';').each { |s|
      @cdbc.session(s.split(':')){ |cmd| yield cmd }
    }
  end

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

  def auto_thread
    Thread.new {
      begin
        loop{
          setcmd(@var[:cmd]){|c| @q.push(c) } if @q.empty?
          sleep @var[:int].to_i
        }
      rescue
        @errmsg << $!.to_s
      end
    }
  end

end
