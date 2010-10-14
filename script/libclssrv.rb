#!/usr/bin/ruby
require "libcls"
require "libdev"
require "thread"

class ClsSrv < Hash
  attr_reader :server

  def initialize(cls,iocmd,obj=nil)
    @cdb=Cls.new(cls,obj)
    @var={:cmd=>'upd',:int=>'10',:cls => cls,:issue =>''}
    @server=@cdb['server']
    @ddb=DevCom.new(@cdb['device'],iocmd,obj)
    @cdb.get_stat(@ddb.field)
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

  def dispatch(line)
    resp=@errmsg.shift
    return resp if resp
    return '' if line.empty?
    cmdary=line.split(' ')
    case cmdary.shift
    when 'stat'
      yield @cdb.stat
    when 'set'
      @ddb.set(cmdary)
    when 'save'
      yield @cdb.get_stat(@ddb.save(*cmdary))
    when 'load'
      yield @cdb.get_stat(@ddb.load(*cmdary))
    when 'auto'
      auto_upd(cmdary)
    else
      begin
        @cdb.getcmd(line) {|cmd| @q.push(cmd)}
      rescue
        raise $! unless /^==/ === $!.to_s
        msg=[$!.to_s]
        msg << "== Internal Command =="
        msg << " stat      : Show Status"
        msg << " set ?     : Set Field [key(:index)(=val)]"
        msg << " save ?    : Save Field [key] (tag)"
        msg << " load ?    : Load Field [key] (tag)"
        msg << " auto ?    : Auto Update (opt)"
        raise msg.join("\n")
      end
      "Accepted"
    end
  rescue
    e2s
  end

  private
  def device_thread
    Thread.new {
      loop {
        cmd=@q.shift
        @var[:issue]='*'
        begin
          @ddb.devcom(cmd)
          @cdb.get_stat(@ddb.field)
        rescue
          @errmsg << e2s
        ensure
          @var[:issue]=''
        end
      }
    }
  end

  def auto_upd(cmds)
    str=''
    cmds.each { |cmd|
      case cmd
      when 'stop'
        if @auto
          @auto.kill
          sleep 0.1
        end
      when 'start'
        @auto.kill if @auto
        @auto=Thread.new {
          begin
            loop{
              @var[:cmd].split(';').each {|c| session(c)} if @q.empty?
              sleep @var[:int].to_i
            }
          rescue
            @errmsg << e2s
          end
        }
      when /^int=/
        num=$'
        if num.to_i > 0
          @var[:int]=num
        else
          raise "Out of Range"
        end
      when /^cmd=/
        line=$'
        line.split(";").each{|c| @cdb.setcmd(c)}
        @var[:cmd]=line
      else
        msg=["== option list =="]
        msg << " start      : Start Auto update"
        msg << " stop       : Stop Auto update"
        msg << " cmd=       : Set Commands (cmd:par;..)"
        msg << " int=       : Set Interval (sec)"
        raise msg.join("\n")
      end
    }
    str << "Not " unless @auto.alive?
    str << "Running(cmd=[#{@var[:cmd]}] int=[#{@var[:int]}])"
  end

  def e2s
    msg=[$!.to_s]
    msg << $@.to_s if ENV['VER']
    msg.join("\n")
  end
end
